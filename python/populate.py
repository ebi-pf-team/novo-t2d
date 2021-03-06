#!/usr/bin/env python3

import requests
import time
import logging
import argparse
import re
import os
import sys
import urllib
import json
import pymysql


# Populate NovoNordisk database, pulling data from UniProt proteins API and other sources

# Fixes needed:
# - kegg.disease
# - IPRs with multiple children (only one taken at present) - check query
# - kegg_step via API - streamline?
# - target - populate acc/source, possibly from second script
# - reactome version
# - auto generate schema?


# Convenience class for unpacking the protein json string
class Protein(object):
  def __init__(self, obj):
    self.acc = obj['accession']
    self.id = obj['id']
    self.org_id = obj['organism']['taxonomy']
    self.reviewed = 1 if obj['info']['type'] == 'Swiss-Prot' else 0

    self.genes = []
    if 'gene' in obj:
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


def get_args(args):
    parser = argparse.ArgumentParser(prog = args[0])
    parser.add_argument('-t', '--tr', action ='store_true', dest = 'trembl', required = False, help = 'Include TrEMBL')
    parser.add_argument("-l", "--log", help = "log file", dest = "log", action = "store", required = False)
    return vars(parser.parse_args())


ip_type_dict = {
  'family': 'Family',
  'domain': 'Domain',
  'repeat': 'Repeat',
  'conserved_site': 'conserved site',
  'homologous_superfamily': 'Homologous Superfamily',
  'active_site': 'active site',
  'binding_site': 'binding site',
  'ptm': 'PTM site',
}


def get_ip_entry(entry_acc):
  url = 'https://www.ebi.ac.uk/interpro/api/entry/InterPro/%s' % (entry_acc)
  entry = json.loads(get_url(url))['metadata']
  entry_type = ip_type_dict[entry['type']]
  entry_name = entry['name']['short']
  num_proteins = entry['counters']['proteins']
  children = entry['hierarchy']['children']
  child = children[0]['accession'] if len(children) else ''
  return [entry_acc, entry_type, entry_name, num_proteins, child, 1]


def get_ip_protein(protein_acc):
  url = 'https://www.ebi.ac.uk/interpro/api/protein/UniProt/%s/entry/InterPro?is_fragment=false' % (protein_acc)
  res = get_url(url)
  if not res:
    return []
  try:
    res = json.loads(res)
  except json.decoder.JSONDecodeError as e:
    log.error("Error decoding InterPro response" + e)
    sys.exit(1)
  if not 'entry_subset' in res:
    log.error("Missing 'entry_subset' field in json for URL " + url + ": " + str(res))
    sys.exit(1)
  entry_subsets = res['entry_subset']
  entries = []
  for entry_subset in entry_subsets:
    for location in entry_subset['entry_protein_locations']:
        entries.append([
            entry_subset['accession'].upper(),
            protein_acc,
            min([f['start'] for f in location['fragments']]),
            max([f['end'] for f in location['fragments']])
        ])

  return entries


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


def reactome_step_columns():
  return ['pathway_id', 'reaction_id', 'reaction_name', 'uniprot_acc', 'reaction_role']


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


def check_entry(cursor, table, column, value):
  cursor.execute('select count(*) from ' + table + ' where ' + column + ' = %s', (value))
  return cursor.fetchone()['count(*)']


def count_table_rows(cursor, table):
  cursor.execute('select count(*) from ' + table)
  return cursor.fetchone()['count(*)']


def nnd_db():
  return pymysql.connect(host        = os.getenv('NND_HOST'),
                         user        = os.getenv('NND_USER'),
                         password    = os.getenv('NND_PASS'),
                         port        = int(os.getenv('NND_PORT')),
                         db          = os.getenv('NND_DB'),
                         charset     = 'utf8',
                         cursorclass = pymysql.cursors.DictCursor)


def get_protein(taxon, trembl, max = -1): # Max for testing purposes
  offset = 0
  count = 0
  batch = 500
  while True:
    if trembl:
      url = "https://www.ebi.ac.uk/proteins/api/proteins?size=%d&isoform=0&taxid=%d&offset=%d" % (batch, taxon, offset)
    else:
      url = "https://www.ebi.ac.uk/proteins/api/proteins?size=%d&isoform=0&taxid=%d&reviewed=true&offset=%d" % (batch, taxon, offset)
    try:
      data = get_url(url)
    except requests.exceptions.HTTPError as e:
      # in case of failure, likely an API timeout: gradually reduce the batch size
      if batch == 500:
        batch = 10
        continue
      if batch == 10:
        batch = 1
        continue
      log.error("Error retrieving UniProt entry from URL " + url)
      sys.exit(1)
    entries = json.loads(data)
    data = None
    if len(entries) == 0:
      return
    for entry in entries:
      if count >= max >= 0:
        return
      count += 1
      yield Protein(entry)
    offset += batch
    # reset batch size
    if offset % 500 == 0:
      batch = 500
    elif offset % 10 == 0 and batch != 500:
      batch = 10


def get_url(url):
  attempt = 0
  while attempt <= 3:
    try:
      r = requests.get(url, headers = { "Accept" : "application/json"}, timeout = 30)
      r.encoding = 'utf8'
      if not r.ok:
        raise requests.exceptions.HTTPError
      return r.text
    except (requests.exceptions.ConnectionError, requests.exceptions.HTTPError, requests.exceptions.ReadTimeout) as e:
      attempt += 1
      time.sleep(3)
  raise requests.exceptions.HTTPError("Error retrieving " + url)


def get_kegg_protein(pid):
  try:
    kegg_entry = get_url('http://rest.kegg.jp/get/%s' % (pid)).rstrip('\n').split('\n')
  except urllib.error.HTTPError as e:
    if str(e) == 'HTTP Error 404: Not Found':
      return []
  kegg_gene = kegg_protein_desc = None # Check: some KEGG entries are not complete
  kegg_pathways = []
  for line in kegg_entry:
    if line.startswith('NAME'):
      m = re.match('NAME\s+(\w+),?', line)
      kegg_gene = m.group(1)
    elif line.startswith('DEFINITION'):
      m = re.match('DEFINITION\s+\(\w+\)\s+(.*)', line)
      kegg_protein_desc = m.group(1)
    elif line.startswith('PATHWAY'):
      m = re.match('PATHWAY\s+(\w+)', line)
      kegg_pathways.append(m.group(1))
    elif len(kegg_pathways):
      # have reached pathway lines: handle remaining entries
      if line[0] != ' ':
        break
      m = re.match('\s+(\w+)', line)
      kegg_pathways.append(m.group(1))
  # TODO: should we permit KEGG entries without genes/descriptions?
  if len(kegg_pathways) and not kegg_gene:
    log.info("KEGG protein " + kegg_protein_id + ": no gene name")
  if len(kegg_pathways) and not kegg_protein_desc:
    log.info("KEGG protein " + kegg_protein_id + ": no description")
# if not len(kegg_pathways):
#   log.info("KEGG protein " + kegg_protein_id + ": no pathways")
  return [kegg_gene, kegg_protein_desc, kegg_pathways]
 

nnd_conn = nnd_db()

# Table: versions

args = get_args(sys.argv)

log = logging.getLogger()
log.setLevel(logging.INFO)
if args['log']:
  handler = logging.FileHandler(args['log'])
else:
  handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter('%(asctime)s: %(message)s', "%Y-%m-%d %H:%M:%S"))
log.addHandler(handler)

cp_versions = urllib.request.urlopen('ftp://ftp.ebi.ac.uk/pub/databases/intact/complex/').read().decode('utf-8').rstrip('\n').replace('\r','').split('\n')
for line in cp_versions:
  m = re.match('.*current -> (\d{4}-\d{2}-\d{2})', line)
  if m:
    cp_version = m.group(1)
    break

ukb = urllib.request.urlopen('ftp://ftp.ebi.ac.uk/pub/databases/uniprot/current_release/relnotes.txt').read().decode('utf-8').rstrip('\n')
m = re.match('UniProt Release (\d{4}_\d{2})', ukb)
if m:
  ukb_version = m.group(1)

kegg_info = get_url('http://rest.kegg.jp/info/kegg').rstrip('\n').split('\n')
for line in kegg_info:
  m = re.match('.*Release\s+(.*)', line)
  if m:
    kegg_version = m.group(1)
    break

with nnd_conn.cursor() as cursor:
  version_sql = insert_sql('versions', version_columns())
  cursor.execute('delete from versions')
  cursor.execute(version_sql, ('Complex portal', cp_version))
  cursor.execute(version_sql, ('UniProtKB', ukb_version))
  cursor.execute(version_sql, ('KEGG', kegg_version))
  nnd_conn.commit()

# Pull orthologs and reactome reactions now as it's quicker to get for
# all proteins

# Get orthologs

orthologs = {}
for orth_species in [10090, 10116]:
  for protein in get_protein(orth_species, args['trembl']):
    for ko in protein.ko:
      if not ko in orthologs:
        orthologs[ko] = []
      orthologs[ko].append([protein.acc, protein.org_id])
  log.info("Obtained orthologs for " + str(orth_species))

# Get reactome reactions

reactions = {}
reactome_steps = {}
# Export from reactome team, may change if available via web?
with open("reactome_reaction_exporter.txt") as fh:
  for line in fh:
    fields = line.rstrip().split('\t')
    fields[-1] = fields[-1].replace('"', '')
    pathway_id = fields[0]
    ukb = fields[3]
    if not ukb in reactions:
      reactions[ukb] = []
    reactions[ukb].append(fields)
    if not pathway_id in reactome_steps:
      reactome_steps[pathway_id] = set()
    reactome_steps[pathway_id].add(fields[1])
log.info("Obtained reactome reactions")

# Populate tables which don't link directly to protein:
# complex_portal, kegg, reactome

# Table: complex_portal

cp = urllib.request.urlopen('ftp://ftp.ebi.ac.uk/pub/databases/intact/complex/current/complextab/homo_sapiens.tsv').read().decode('utf-8').rstrip('\n').split('\n')
complex_sql = insert_sql('complex_portal', complex_portal_columns())
with nnd_conn.cursor() as cursor:
  # Skip if already filled, or delete?
  if not count_table_rows(cursor, 'complex_portal'):
    for line in cp:
      if line.startswith('#Complex ac'):
        continue
      f = line.split('\t')
      cursor.execute(complex_sql, (f[0], f[1], 1 + f[4].count('|')))
    nnd_conn.commit()
log.info("Done table complex_portal")

# Table: kegg

kegg_desc = {}
keggs = get_url('http://rest.kegg.jp/list/pathway').rstrip('\n').split('\n')
# Get descriptions
for line in keggs:
  acc, desc = line.rstrip('\n').split('\t', maxsplit = 1)
  acc = acc.replace('path:map', 'hsa') # Yuk, check API to see if there's a better way
  kegg_desc[acc] = desc

keggs = get_url('http://rest.kegg.jp/link/hsa/pathway').rstrip('\n').split('\n')
kegg_counts = {}
kegg_sql = insert_sql('kegg', kegg_columns())
with nnd_conn.cursor() as cursor:
  for line in keggs:
    acc, step = line.split('\t')
    acc = acc.replace('path:', '')
    # Skip if already have this accession
    if check_entry(cursor, 'kegg', 'kegg_pathway_id', acc):
      continue
    if not acc in kegg_counts:
      kegg_counts[acc] = 0
    kegg_counts[acc] += 1
  for kegg in kegg_counts:
    if not kegg in kegg_desc:
      log.info("No description for " + kegg + "\n")
      kegg_desc[kegg] = ''
    cursor.execute(kegg_sql, (kegg, kegg_desc[kegg], kegg_counts[kegg], ""))
  nnd_conn.commit()
log.info("Done table kegg")

# Table: reactome

reactome_sql = insert_sql('reactome', reactome_columns())
with nnd_conn.cursor() as cursor:
  if not count_table_rows(cursor, 'reactome'):
    reactomes = set()
    reactome = get_url('https://reactome.org/download/current/UniProt2Reactome.txt').rstrip('\n').split('\n')
    for line in reactome:
      f = line.split('\t')
      if f[5] != 'Homo sapiens':
        continue
      r = (f[1], f[3], f[5], len(reactome_steps[f[1]]))
      if not r in reactomes:
        reactomes.add(r)

    for r in reactomes:
      cursor.execute(reactome_sql, r)
    nnd_conn.commit()
log.info("Done table reactome")

# Fill protein and all other tables that hang off it

with nnd_conn.cursor() as cursor:
  nnd_conn.ping(reconnect = True)
  protein_sql = insert_sql('protein', protein_columns())
  kegg_step_sql = insert_sql('kegg_step', kegg_step_columns())
  reactome_step_sql = insert_sql('reactome_step', reactome_step_columns())
  go_sql = insert_sql('gene_ontology', go_columns())
  ensembl_sql = insert_sql('ensembl_transcript', ensembl_columns())
  complex_sql = insert_sql('complex_component', complex_component_columns())
  pdb_sql = insert_sql('pdb', pdb_columns())
  ortholog_sql = insert_sql('ortholog', ortholog_columns())
  interpro_sql = insert_sql('interpro', interpro_columns())
  match_sql = insert_sql('interpro_match', interpro_match_columns())

  ip_loaded = set()

  count = 0
  for protein in get_protein(9606, args['trembl']):
    # Skip existing entires; may want to make this optional for speed?
    if check_entry(cursor, 'protein', 'uniprot_acc', protein.acc):
      continue
    cursor.execute(protein_sql, (protein.acc, protein.id, protein.reviewed, ','.join(protein.genes), protein.name, str(protein.org_id), ';'.join(protein.enst_f), ';'.join(protein.complex_portal_xref), ';'.join(protein.reactome_xref), ';'.join(protein.kegg_xref), protein.secreted, ';'.join(protein.proteomes)))
    count += 1

    for enst in protein.enst:
      cursor.execute(ensembl_sql, (protein.acc, enst[1], enst[0]))

    if protein.acc in reactions:
      for reaction in reactions[protein.acc]:
        cursor.execute(reactome_step_sql, reaction)

    protein_orthologs = set() # Account for identical orthologs mapping > once via different KOs
    for ko in protein.ko:
      if ko in orthologs:
        for ortholog in orthologs[ko]:
          protein_orthologs.add((protein.acc, ortholog[0], ortholog[1]))
    for po in protein_orthologs:
      cursor.execute(ortholog_sql, po)

    for pdb in protein.pdb:
      cursor.execute(pdb_sql, (protein.acc, pdb[0], pdb[1]))
    
    for go in protein.go:
      cursor.execute(go_sql, (protein.acc, go[0], go[1], go[2]))
    
    for cp in protein.complex_portal_xref:
      cursor.execute(complex_sql, (cp, protein.acc))
    
    ip_proteins = get_ip_protein(protein.acc)

    # Load any InterPro entries ...
    for ip_protein in ip_proteins:
      if ip_protein[0] in ip_loaded:
        continue
      if check_entry(cursor, 'interpro', 'interpro_acc', ip_protein[0]):
        ip_loaded.add(ip_protein[0])
        continue
      entry = get_ip_entry(ip_protein[0])
      cursor.execute(interpro_sql, entry)
      ip_loaded.add(ip_protein[0])

    # ... followed by the matches themselves
    for ip_protein in ip_proteins:
      cursor.execute(match_sql, ip_protein)

    kegg_proteins = {}

    # kegg_step
    res = get_url('http://rest.kegg.jp/conv/genes/up:%s' % (protein.acc)).rstrip('\n')
    if res:
      kegg_protein_ids = res.split('\n')
      # Convert UKB acc to kegg protein acc
      for kegg_protein_id in kegg_protein_ids:
        kegg_protein_id = kegg_protein_id.split('\t')[1] # above returns two IDs; skip the first [UKB] accession
        # This API call seems slow, esp when we might loop over TrEMBL
        if not kegg_protein_id in kegg_proteins:
          entry = get_kegg_protein(kegg_protein_id)
          if len(entry) == 0:
            log.info("KEGG protein " + kegg_protein_id + " not found")
            continue
          kegg_proteins[kegg_protein_id] = entry
        kegg_gene = kegg_proteins[kegg_protein_id][0]
        kegg_protein_desc = kegg_proteins[kegg_protein_id][1]
        kegg_pathways = kegg_proteins[kegg_protein_id][2]
        for kegg_pathway in kegg_pathways:
          cursor.execute(kegg_step_sql, (kegg_pathway, protein.acc, kegg_protein_id, kegg_gene, kegg_protein_desc))

    nnd_conn.commit()

    if not count % 1000:
      # May want to make this output an option?
      log.info('Loaded: ' + str(count))
      sys.stdout.flush()

  log.info('Loaded: ' + str(count))

