import requests
import re
import os
import sys
import urllib
import json
import pymysql
import cx_Oracle


# Populate NovoNordisk database, pulling data from UniProt proteins API and other sources

# Fixes needed:
# - kegg disease
# - IPRs with multiple children (only one taken at present) - check query
# - interpro_match start/end
# - reactome_step
# - kegg_step
# - target - transfer/update from previous version?
# - versions
# - auto generate schema?
# - UniProt proteins API - failures, esp. when including TrEMBL


# Convenience class for unpacking the protein json string
class Protein(object):
  def __init__(self, obj):
    self.acc = obj['accession']
    self.id = obj['id']
    self.org_id = obj['organism']['taxonomy']
    self.type = 'reviewed' if obj['info']['type'] == 'Swiss-Prot' else 'unreviewed'
    self.reviewed = 1 if obj['info']['type'] == 'Swiss-Prot' else 0

    self.genes = []
    if 'gene' in obj:# and 'name' in obj['gene']:
      for gene in obj['gene']:
        if 'name' in gene:
          self.genes.append(gene['name']['value'])

    self.secreted = 0
    if 'keywords' in obj:
      for kw in obj['keywords']:
        if kw['value'] in ['Signal', 'Secreted']:
          self.secreted = 1
          break

    if 'recommendedName' in obj['protein']:
      self.name = obj['protein']['recommendedName']['fullName']['value']
    # submitted appears to be an array
    elif 'submittedName' in obj['protein']:
      self.name = obj['protein']['submittedName'][0]['fullName']['value']

    self.enst = []
    self.enst_f = [] # formatted version with isoform in []
    self.complex_portal_xref = []
    self.reactome_xref = []
    self.kegg_xref = []
    self.proteomes = []
    self.ko = []
    self.pdb = []
    self.go = []
    go_dict = {
      'F': 'MF',
      'C': 'CC',
      'P': 'BP'
    }
    for db_ref in obj['dbReferences']:
      if db_ref['type'] == 'Ensembl':
        et = [ db_ref['id'] ]
        etf = db_ref['id']
        if 'isoform' in db_ref:
          et.append(db_ref['isoform'])
          etf = etf + ' [' + db_ref['isoform'] + ']'
        else:
          et.append('')
        self.enst.append(et)
        self.enst_f.append(etf)
      elif db_ref['type'] == 'ComplexPortal':
        self.complex_portal_xref.append(db_ref['id'])
      elif db_ref['type'] == 'Reactome':
        self.reactome_xref.append(db_ref['id'])
      elif db_ref['type'] == 'KEGG':
        self.kegg_xref.append(db_ref['id'])
      elif db_ref['type'] == 'KO':
        self.ko.append(db_ref['id'])
      elif db_ref['type'] == 'Proteomes':
        self.proteomes.append(db_ref['id'])
      elif db_ref['type'] == 'PDB':
        if 'chains' in db_ref['properties']:
          chains = db_ref['properties']['chains'].split('=', maxsplit = 1)[0].split('/')
          for chain in chains:
            self.pdb.append([db_ref['id'], chain])
      elif db_ref['type'] == 'GO':
        go = db_ref['properties']['term'].split(':', maxsplit = 1)
        self.go.append([db_ref['id'], go_dict[go[0]], go[1]])


def get_ip_entry(conn, entry_acc):
  cur = conn.cursor()
  cur.execute(
    """
    select
      e.entry_ac, e.entry_type, e.short_name, em.protein_count,
      e2e.entry_ac, e.checked
    from interpro.entry e
    join interpro.mv_entry_match em
      on (em.entry_ac=e.entry_ac)
    left join interpro.entry2entry e2e
      on (e2e.parent_ac=e.entry_ac)
    where e.entry_ac = :1
    """, (entry_acc,))

  # rows = cur.fetchall() # FIXME: IPR with multiple children
  rows = cur.fetchone()
  cur.close()
  return rows


def get_ip_proteins(conn, protein_acc):
  cur = conn.cursor()
  cur.execute(
    """
    select entry_ac, protein_ac, 1, 0
    from interpro.mv_entry2protein
    where protein_ac = :1
    """, (protein_acc,)) # start, end in interpro_match = 1, 0?
  rows = cur.fetchall()
  cur.close()
  return rows


def insert_sql(table, columns): # Hardcoded column order, bad
  sql = "INSERT INTO `%s`" % (table) + ' ('
  sql += ','.join([ '`' + col + '`' for col in columns ])
  sql += ') VALUES ('
  sql += ','.join([ '%s' for col in columns ]) + ')'
  return sql


def version_columns():
  return ['resource', 'version']


def kegg_step_columns():
  return ['kegg_pathway_id', 'uniprot_acc', 'kegg_protein', 'kegg_gene', 'kegg_protein_desc']


def kegg_columns(): # Description and disease are missing
  return ['kegg_pathway_id', 'description', 'number_steps', 'kegg_disease']


def reactome_columns():
  return ['pathway_id', 'description', 'species', 'number_steps']


def interpro_match_columns():
  return ['interpro_acc', 'uniprot_acc', 'start', 'end']


def interpro_columns():
  return ['interpro_acc', 'ipr_type', 'short_name', 'num_matches', 'child_interpro_acc', 'checked']


def complex_portal_columns():
  return ['complex_portal_accession', 'description', 'number_proteins']


def protein_columns():
  return ['uniprot_acc', 'uniprot_id', 'reviewed',
    'gene_name', 'description', 'species', 'ensembl_gene',
    'complex_portal_xref', 'reactome_xref', 'kegg_xref', 'secreted', 'proteome']


def go_columns():
  return ['uniprot_acc', 'go_id', 'go_class', 'go_name']


def complex_component_columns():
  return ['complex_portal_accession', 'uniprot_acc']


def pdb_columns():
  return ['uniprot_acc', 'pdb_id', 'chain']


def ortholog_columns():
  return ['uniprot_acc', 'ortholog_uniprot_acc', 'species']


def ensembl_columns():
  return ['uniprot_acc', 'uniprot_isoform', 'ensembl_transcript_acc']


def count_table_rows(cursor, table):
  cursor.execute('select count(*) from ' + table)
  return cursor.fetchone()['count(*)']


def nnd_db():
  return pymysql.connect(host        = 'localhost',
                         user        = os.getenv('NND_USER'),
                         password    = os.getenv('NND_PASS'),
                         db          = os.getenv('NND_DB'),
                         charset     = 'utf8',
                         cursorclass = pymysql.cursors.DictCursor)


def ip_db():
  return cx_Oracle.connect(user     = os.getenv('IP_USER'),
                           password = os.getenv('IP_PASS'),
                           dsn      = cx_Oracle.makedsn('ora-vm5-019.ebi.ac.uk',
                                                        '1531',
                                                         service_name = 'IPPRO'))


def get_protein(taxon, max = -1): # Max for testing purposes
  offset = 0
  count = 0
  while True:
    url = "https://www.ebi.ac.uk/proteins/api/proteins?size=500&isoform=0&taxid=%d&reviewed=true&offset=%d" % (taxon, offset)
  # url = "https://www.ebi.ac.uk/proteins/api/proteins?size=500&isoform=0&taxid=%d&offset=%d" % (taxon, offset)
    entries = json.loads(get_url(url))
    if len(entries) == 0:
      return
    for entry in entries:
      if count >= max >= 0:
        return
      count += 1
      yield Protein(entry)
    offset += 500


def get_url(url):
  r = requests.get(url, headers = { "Accept" : "application/json"})
  if not r.ok:
    r.raise_for_status()
    sys.exit()
  return r.text


nnd_conn = nnd_db()
ip_conn = ip_db()

cp_versions = urllib.request.urlopen('ftp://ftp.ebi.ac.uk/pub/databases/intact/complex/').read().decode('utf-8').rstrip('\n').replace('\r','').split('\n')
for line in cp_versions:
  m = re.match('.*current -> (\d{4}-\d{2}-\d{2})', line)
  if m:
    cp_version = m.group(1)

ukb = urllib.request.urlopen('ftp://ftp.ebi.ac.uk/pub/databases/uniprot/current_release/relnotes.txt').read().decode('utf-8').rstrip('\n')
m = re.match('UniProt Release (\d{4}_\d{2})', ukb)
if m:
  ukb_version = m.group(1)

with nnd_conn.cursor() as cursor:
  version_sql = insert_sql('versions', version_columns())
  cursor.execute(version_sql, ('Complex portal', cp_version))
  cursor.execute(version_sql, ('UniProtKB', ukb_version))
  nnd_conn.commit()

cp = urllib.request.urlopen('ftp://ftp.ebi.ac.uk/pub/databases/intact/complex/current/complextab/homo_sapiens.tsv').read().decode('utf-8').rstrip('\n').split('\n')
complex_sql = insert_sql('complex_portal', complex_portal_columns())
with nnd_conn.cursor() as cursor:
  if not count_table_rows(cursor, 'complex_portal'):
    for line in cp:
      if line.startswith('#Complex ac'):
        continue
      f = line.split('\t')
      cursor.execute(complex_sql, (f[0], f[1], 1 + f[4].count('|')))
    nnd_conn.commit()

kegg_desc = {}
keggs = urllib.request.urlopen('http://rest.kegg.jp/list/pathway').read().decode('utf-8').rstrip('\n').split('\n')
for line in keggs:
  acc, desc = line.rstrip('\n').split('\t', maxsplit = 1)
  acc = acc.replace('path:map', 'hsa') # Yuk, check API to see if there's a better way
  kegg_desc[acc] = desc

keggs = urllib.request.urlopen('http://rest.kegg.jp/link/hsa/pathway').read().decode('utf-8').rstrip('\n').split('\n')
kegg_counts = {}
kegg_sql = insert_sql('kegg', kegg_columns())
with nnd_conn.cursor() as cursor:
  if not count_table_rows(cursor, 'kegg'):
    for line in keggs:
      acc, step = line.split('\t')
      acc = acc.replace('path:', '')
      if not acc in kegg_counts:
        kegg_counts[acc] = 0
      kegg_counts[acc] += 1
    for kegg in kegg_counts:
      cursor.execute(kegg_sql, (kegg, kegg_desc[kegg], kegg_counts[kegg], ""))
    nnd_conn.commit()

reactome_sql = insert_sql('reactome', reactome_columns())
with nnd_conn.cursor() as cursor:
  if not count_table_rows(cursor, 'reactome'):
    reactomes = {}
    reactome = urllib.request.urlopen('https://reactome.org/download/current/UniProt2Reactome.txt').read().decode('utf-8').rstrip('\n').split('\n')
    for line in reactome:
      f = line.split('\t')
      if f[5] != 'Homo sapiens':
        continue
      if not (f[1], f[3], f[5]) in reactomes:
        reactomes[(f[1], f[3], f[5])] = 0
      reactomes[(f[1], f[3], f[5])] += 1

    for r in reactomes:
      cursor.execute(reactome_sql, (r[0], r[1], r[2], reactomes[(r[0], r[1], r[2])]))
    nnd_conn.commit()

orthologs = {}
for protein in get_protein(10090):
  for ko in protein.ko:
    if not ko in orthologs:
      orthologs[ko] = []
    orthologs[ko].append([protein.acc, protein.org_id])

with nnd_conn.cursor() as cursor:
  protein_sql = insert_sql('protein', protein_columns())
  go_sql = insert_sql('gene_ontology', go_columns())
  ensembl_sql = insert_sql('ensembl_transcript', ensembl_columns())
  complex_sql = insert_sql('complex_component', complex_component_columns())
  pdb_sql = insert_sql('pdb', pdb_columns())
  ortholog_sql = insert_sql('ortholog', ortholog_columns())
  interpro_sql = insert_sql('interpro', interpro_columns())
  match_sql = insert_sql('interpro_match', interpro_match_columns())
  ip_loaded = set()
  ip_type_dict = {
    'F': 'Family',
    'D': 'Domain',
    'R': 'Repeat',
    'C': 'conserved site',
    'H': 'Homologous Superfamily',
    'A': 'active site',
    'B': 'binding site',
    'P': 'PTM site'
  }

  for protein in get_protein(9606):
    cursor.execute(protein_sql, (protein.acc, protein.id, protein.reviewed, ','.join(protein.genes), protein.name, str(protein.org_id), ';'.join(protein.enst_f), ';'.join(protein.complex_portal_xref), ';'.join(protein.reactome_xref), ';'.join(protein.kegg_xref), protein.secreted, ';'.join(protein.proteomes)))

    for enst in protein.enst:
      cursor.execute(ensembl_sql, (protein.acc, enst[1], enst[0]))

    protein_orthologs = set() # Account for identical orthologs mapping > once via different KOs
    for ko in protein.ko:
      if ko in orthologs:
        for ortholog in orthologs[ko]:
          protein_orthologs.add((ortholog[0], ortholog[1]))
    for po in protein_orthologs:
      cursor.execute(ortholog_sql, (protein.acc, po[0], po[1]))

    for pdb in protein.pdb:
      cursor.execute(pdb_sql, (protein.acc, pdb[0], pdb[1]))
    
    for go in protein.go:
      cursor.execute(go_sql, (protein.acc, go[0], go[1], go[2]))
    
    for cp in protein.complex_portal_xref:
      cursor.execute(complex_sql, (cp, protein.acc))
    
    for ip_protein in get_ip_proteins(ip_conn, protein.acc):
      if not ip_protein[0] in ip_loaded:
        entry = list(get_ip_entry(ip_conn, ip_protein[0]))
        entry[1] = ip_type_dict[entry[1]]
        entry[5] = 1 if entry[5] == 'Y' else 0
        cursor.execute(interpro_sql, entry)
        ip_loaded.add(ip_protein[0])
      cursor.execute(match_sql, ip_protein)

  nnd_conn.commit()

