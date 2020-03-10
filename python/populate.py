#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import logging
import os
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib import request

import pymysql
import requests

logging.basicConfig(format="%(asctime)s: %(message)s",
                    datefmt='%Y-%m-%d %H:%M:%S',
                    level=logging.INFO)
logger = logging.getLogger("nnd")


def fetch(url):
    return request.urlopen(url).read().decode("utf-8")


def fetch_complex_version():
    data = fetch("ftp://ftp.ebi.ac.uk/pub/databases/intact/complex/")
    for line in data.split('\n'):
        m = re.search("current\s*->\s*(\d{4}-\d{2}-\d{2})", line)
        if m:
            return m.group(1)

    raise RuntimeError("could not detect Complex Portal version")


def fetch_kegg_version():
    data = fetch("http://rest.kegg.jp/info/kegg")
    for line in data.split('\n'):
        m = re.search("Release\s*(.+)", line.strip())
        if m:
            return m.group(1)

    raise RuntimeError("could not detect KEGG version")


def fetch_reactome_version():
    data = fetch("https://reactome.org/ContentService/data/database/version")
    return data.strip()


def fetch_uniprot_version():
    data = fetch("ftp://ftp.ebi.ac.uk/pub/databases/uniprot/current_release/relnotes.txt")
    m = re.search('UniProt Release (\d{4}_\d{2})', data)
    if m:
        return m.group(1)

    raise RuntimeError("could not detect UniProtKB version")


class UniProtEntry(object):
    def __init__(self, obj):
        self.accession = obj["accession"]
        self.identifer = obj["id"]
        self.taxid = obj["organism"]["taxonomy"]
        self.is_reviewed = obj["info"]["type"] == "Swiss-Prot"
        self.genes = []
        for g in obj.get("gene", []):
            try:
                name = g["name"]["value"]
            except (KeyError, TypeError):
                continue
            else:
                self.genes.append(name)

        self.is_secreted = False
        for kw in obj.get("keywords", []):
            if kw["value"] in ("Signal", "Secreted"):
                self.is_secreted = True
                break

        self.name = self.select_name(obj["protein"])
        if self.name is None:
            raise ValueError("could not find a name for {}".format(self.accession))

        self.xrefs = {
            "ComplexPortal": [],
            "Ensembl": [],
            "GO": [],
            "KEGG": [],
            "KO": [],
            "PDB": [],
            "Proteomes": [],
            "Reactome": []
        }
        for ref in obj.get("dbReferences", []):
            ref_type = ref["type"]

            if ref_type in ("ComplexPortal", "KEGG", "KO", "Proteomes", "Reactome"):
                self.xrefs[ref["type"]].append(ref["id"])
            elif ref_type == "Ensembl":
                self.xrefs[ref_type].append((ref["id"], ref.get("isoform")))
            elif ref_type == "GO":
                # e.g. P:immune response
                aspect, name = ref["properties"]["term"].split(':', maxsplit=1)
                if aspect == 'C':
                    aspect = "CC"
                elif aspect == 'F':
                    aspect = "MF"
                else:  # should be 'P'
                    aspect = "BP"
                self.xrefs[ref_type].append((ref["id"], aspect, name))
            elif ref_type == "PDB":
                try:
                    chains = ref["properties"]["chains"]
                except (KeyError, TypeError):
                    continue
                else:
                    # e.g. D/I=20-109
                    for chain in chains.split('=', 1)[0].split('/'):
                        self.xrefs[ref_type].append((ref["id"], chain))

    @staticmethod
    def select_name(obj):
        try:
            return obj["recommendedName"]["fullName"]["value"]
        except (KeyError, TypeError):
            pass

        try:
            return obj["submittedName"][0]["fullName"]["value"]
        except (KeyError, IndexError, TypeError):
            pass

        return None

    @property
    def ensembl(self):
        references = []
        for transcript_id, isoform in self.xrefs["Ensembl"]:
            if isoform:
                references.append("{} [{}]".format(transcript_id, isoform))
            else:
                references.append(transcript_id)
        return references

    def astuple(self):
        return (
            self.accession,
            self.identifer,
            1 if self.is_reviewed else 0,
            ','.join(self.genes),
            self.name,
            str(self.taxid),
            ';'.join(self.ensembl),
            ';'.join(self.xrefs["ComplexPortal"]),
            ';'.join(self.xrefs["Reactome"]),
            ';'.join(self.xrefs["KEGG"]),
            1 if self.is_secreted else 0,
            ';'.join(self.xrefs["Proteomes"])
        )


def fetch_uniprot(taxid, size=100):
    default_size = size
    url = "https://www.ebi.ac.uk/proteins/api/proteins"
    offset = 0
    while True:
        params = {
            "offset": offset,
            "isoform": 0,
            "taxid": taxid,
            "size": size
        }

        r = requests.get(url, params=params, headers={"Accept": "application/json"})
        if r.status_code == 500 and size > 1:
            size = max(1, size//2)
            continue

        entries = r.json()
        if not entries:
            break

        for obj in entries:
            yield UniProtEntry(obj)

        offset += len(entries)
        size = default_size


def fetch_complex_data():
    url = "ftp://ftp.ebi.ac.uk/pub/databases/intact/complex/current/complextab/homo_sapiens.tsv"
    data = fetch(url)
    lines = iter(data.rstrip().split('\n'))
    next(lines)  # skip header
    for line in lines:
        fields = line.split('\t')
        accession = fields[0]
        recommended_name = fields[1]
        molecules = fields[4].split('|')
        identifers = []

        for item in molecules:
            # Format: identifer(stoichiometry), e.g. P10415(1)
            identifers.append(re.match("(.+)\(\d+\)$", item).group(1))

        yield accession, recommended_name, len(molecules), set(identifers)


def fetch_kegg_data():
    url = "http://rest.kegg.jp/conv/uniprot/hsa"
    r = requests.get(url, stream=True)
    kegg2uniprot = {}
    for line in r.iter_lines(decode_unicode=True):
        m = re.match("(hsa:\d+)\s+up:([A-Z0-9]+)", line)
        hsa, up = m.groups()

        try:
            kegg2uniprot[hsa].add(up)
        except KeyError:
            kegg2uniprot[hsa] = {up}

    url = "http://rest.kegg.jp/list/hsa"
    r = requests.get(url, stream=True)
    proteins = {}
    for line in r.iter_lines(decode_unicode=True):
        hsa, info = line.rstrip().split('\t')
        try:
            genes, desc = info.split(';')
        except ValueError:
            continue

        gene = genes.split(',')[0].strip()
        desc = desc.strip()

        for up in kegg2uniprot.get(hsa, []):
            try:
                proteins[hsa].append((gene, desc, up))
            except KeyError:
                proteins[hsa] = [(gene, desc, up)]

    url = "http://rest.kegg.jp/link/hsa/pathway"
    r = requests.get(url, stream=True)
    links = {}
    for line in r.iter_lines(decode_unicode=True):
        pathway_id, hsa = line.split('\t')
        try:
            links[pathway_id].add(hsa)
        except KeyError:
            links[pathway_id] = {hsa}

    url = "http://rest.kegg.jp/list/pathway/hsa"
    r = requests.get(url, stream=True)
    descriptions = {}
    for line in r.iter_lines(decode_unicode=True):
        pathway_id, description = line.split('\t')
        descriptions[pathway_id] =re.sub("\s*-\s*Homo sapiens \(human\)", "", description)

    pathways = []
    for pathway_id, pathway_proteins in links.items():
        steps = []
        for hsa in pathway_proteins:
            for gene, desc, up in proteins.get(hsa, []):
                steps.append((up, hsa, gene, desc))

        pathways.append((
            re.sub("^path:", "", pathway_id),
            descriptions.get(pathway_id, ""),
            len(pathway_proteins),
            None,
            steps
        ))

    return pathways


def fetch_orthologs(taxids):
    orthologs = {}
    for taxid in taxids:
        for p in fetch_uniprot(taxid):
            for koid in p.xrefs["KO"]:
                try:
                    orthologs[koid].append((p.accession, p.taxid))
                except KeyError:
                    orthologs[koid] = [(p.accession, p.taxid)]

    return orthologs


def fetch_reactome_reactions(version):
    url = "https://reactome.org/download/current/reactome_reaction_exporter_v{}.txt".format(version)
    r = requests.get(url, stream=True)
    lines = r.iter_lines(decode_unicode=True)
    next(lines)  # skip header

    reactions = {}
    for line in lines:
        fields = line.split('\t')
        pathway_id = fields[0]
        reaction_id = fields[1]
        reaction_name = fields[2]
        uniprot_acc = fields[3]
        reaction_role = fields[4][1:-1]  # trim leading/trailing square brackets

        try:
            obj = reactions[uniprot_acc]
        except KeyError:
            obj = reactions[uniprot_acc] = []
        finally:
            obj.append((pathway_id, reaction_id, reaction_name, reaction_role))

    return reactions


def fetch_reactome_pathways(reactions):
    reactome_steps = {}
    for uniprot_reactions in reactions.values():
        for pathway_id, reaction_id, reaction_name, reaction_role in uniprot_reactions:
            try:
                obj = reactome_steps[pathway_id]
            except KeyError:
                obj = reactome_steps[pathway_id] = set()
            finally:
                obj.add(reaction_id)

    url = "https://reactome.org/download/current/UniProt2Reactome.txt"
    r = requests.get(url, stream=True)
    pathways = {}
    for line in r.iter_lines(decode_unicode=True):
        fields = line.split('\t')
        # uniprot_acc = fields[0]``
        pathway_id = fields[1]
        description = fields[3]
        species = fields[5]

        """
        Since a pathway can be linked to multiple UniProt entries,
        we need to ensure that each pathway is returned only once.
        """
        if pathway_id in pathways or species != "Homo sapiens":
            continue

        pathways[pathway_id] = (
            pathway_id,
            description,
            len(reactome_steps[pathway_id]),
            species
        )

    return list(pathways.values())


def find_node(node, key):
    if node["accession"] == key:
        return node

    for child in node["children"]:
        res = find_node(child, key)
        if res:
            return res

    return None


def fetch_interpro_entry(accession):
    url = "https://www.ebi.ac.uk/interpro/api/entry/InterPro/{}".format(accession)
    while True:
        r = requests.get(url)
        if r.status_code == 200:
            entry = r.json()
            metadata = entry["metadata"]

            entry_type = {
                "family": "Family",
                "domain": "Domain",
                "repeat": "Repeat",
                "conserved_site": "conserved site",
                "homologous_superfamily": "Homologous Superfamily",
                "active_site": "active site",
                "binding_site": "binding site",
                "ptm": "PTM site"
            }[metadata["type"]]

            node = find_node(metadata["hierarchy"], accession)
            try:
                child = node["children"][0]["accession"]
            except IndexError:
                child = None

            return (
                metadata["accession"],
                entry_type,
                metadata["name"]["short"],
                metadata["counters"]["proteins"],
                child,
                1
            )
        elif r.status_code == 408:
            time.sleep(10)
        else:
            raise RuntimeError(url)


def fetch_interpro_version():
    while True:
        r = requests.get("https://www.ebi.ac.uk/interpro/api/")

        try:
            return r.headers["InterPro-Version"]
        except KeyError:
            time.sleep(5)


def fetch_interpro_entries():
    entries = []
    url = "https://www.ebi.ac.uk/interpro/api/entry/InterPro"
    while True:
        r = requests.get(url)

        try:
            data = r.json()
            results = data["results"]
        except (KeyError, ValueError):
            time.sleep(5)
        else:
            for entry in data["results"]:
                entries.append(entry["metadata"]["accession"])

            url = data["next"]
            if url is None:
                break

    return entries


def fetch_interpro_matches(uniprot_acc):
    url = "https://www.ebi.ac.uk/interpro/api/protein/UniProt/{}/entry/InterPro".format(uniprot_acc)
    r = requests.get(url)
    if r.status_code == 200:
        data = r.json()
        entries = []
        for entry in data["entry_subset"]:
            locations = []
            for loc in entry["entry_protein_locations"]:
                locations.append((
                    loc["fragments"][0]["start"],
                    loc["fragments"][0]["end"]
                ))

            entries.append((entry["accession"], locations))

        return entries
    elif r.status_code == 204:
        return []
    else:
        raise RuntimeError("{}: {}".format(r.url, r.status_code))


def main():
    parser = argparse.ArgumentParser(description="Populate Novo Nordisk database")
    parser.add_argument("-t", "--threads",
                        default=4,
                        type=int,
                        metavar="INT",
                        help="number of threads querying the InterPro REST API (default: 4)")
    parser.add_argument("--verbose", action="store_true", help="increase verbosity")
    args = parser.parse_args()

    if args.threads is not None and args.threads < 1:
        parser.error("-t, --threads cannot be smaller than 1")
    elif args.verbose:
        logger.setLevel(logging.DEBUG)

    for key in ("NND_HOST", "NND_USER", "NND_PASS", "NND_DB", "NND_PORT"):
        try:
            os.environ[key]
        except KeyError:
            parser.error("{}: no such environment variable".format(key))

    try:
        int(os.environ["NND_PORT"])
    except ValueError:
        parser.error("NND_PORT: integer expected")

    logger.info("retrieving orthologs")
    # 10090: Mus musculus, 10116: Rattus norvegicus
    orthologs = fetch_orthologs((10090, 10116))

    # Use `passwd` and `db` instead of `password` and `database` for for compatibility to MySQLdb
    con = pymysql.connect(host=os.environ["NND_HOST"],
                          user=os.environ["NND_USER"],
                          passwd=os.environ["NND_PASS"],
                          db=os.environ["NND_DB"],
                          port=int(os.environ["NND_PORT"]))
    cur = con.cursor()

    logger.info("retrieving resources versions")
    cur.executemany("INSERT INTO versions VALUES (%s, %s)",
                    [("Complex portal", fetch_complex_version()),
                    ("UniProtKB", fetch_uniprot_version()),
                    ("KEGG", fetch_kegg_version()),
                    ("Reactome", fetch_reactome_version()),
                    ("InterPro", fetch_interpro_version())])

    logger.info("retrieving Complex Portal data")
    uniprot2complex = {}
    for acc, name, cnt, identifers in fetch_complex_data():
        cur.execute("INSERT INTO complex_portal VALUES (%s, %s, %s)",
                        (acc, name, cnt))

        for _id in identifers:
            try:
                uniprot2complex[_id].add(acc)
            except KeyError:
                uniprot2complex[_id] = {acc}

    logger.info("retrieving Reactome data")
    reactions = fetch_reactome_reactions(fetch_reactome_version())
    cur.executemany("INSERT INTO reactome VALUES (%s, %s, %s, %s)",
                    fetch_reactome_pathways(reactions))

    logger.info("retrieving InterPro entries")
    accessions = fetch_interpro_entries()
    cnt = 0
    with ThreadPoolExecutor(max_workers=args.threads) as executor:
        for obj in executor.map(fetch_interpro_entry, accessions):
            cur.execute("INSERT INTO interpro VALUES (%s, %s, %s, %s, %s, %s)", obj)

            cnt += 1
            if not cnt % 1000 or cnt == len(accessions):
                logger.debug("\t{:>5} / {}".format(cnt, len(accessions)))

    logger.info("retrieving UniProt entries")
    cnt = 0
    accessions = set()
    for up in fetch_uniprot(9606):
        accessions.add(up.accession)

        # Overwrite cross-references to ComplexPortal with mappings from ComplexPortal
        up.xrefs["ComplexPortal"] = uniprot2complex.get(up.accession, [])

        cur.execute(
            """
            INSERT INTO protein
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            up.astuple()
        )

        for transcript_id, isoform in up.xrefs["Ensembl"]:
            cur.execute("INSERT INTO ensembl_transcript VALUES (%s, %s, %s)",
                        (up.accession, isoform, transcript_id))

        for pathway_id, reaction_id, reaction_name, reaction_role in reactions.get(up.accession, []):
            cur.execute("INSERT INTO reactome_step VALUES (%s, %s, %s, %s, %s)",
                        (pathway_id, up.accession, reaction_id, reaction_name, reaction_role))

        _orthologs = set()
        for koid in up.xrefs["KO"]:
            _orthologs |= set(orthologs.get(koid, []))

        for orth_acc, orth_taxid in _orthologs:
            cur.execute("INSERT INTO ortholog VALUES (%s, %s, %s)",
                        (up.accession, orth_acc, orth_taxid))

        for pdb_id, chain in up.xrefs["PDB"]:
            cur.execute("INSERT INTO pdb VALUES (%s, %s, %s)",
                        (up.accession, pdb_id, chain))

        for go_id, go_class, go_name in up.xrefs["GO"]:
            cur.execute("INSERT INTO gene_ontology VALUES (%s, %s, %s, %s)",
                        (up.accession, go_id, go_class, go_name))

        for complex_acc in up.xrefs["ComplexPortal"]:
            try:
                cur.execute("INSERT INTO complex_component VALUES (%s, %s)",
                            (complex_acc, up.accession))
            except pymysql.err.IntegrityError:
                """
                Jan 2020
                Q6QNY1 has a reference to CPX-1912, which is not available in
                the Complex Portal.
                """
                logger.warning("invalid mapping: {} <-> {}".format(complex_acc, up.accession))

        cnt += 1
        if not cnt % 10000:
            logger.debug("\t{:>6}".format(cnt))
    logger.debug("\t{:>6}".format(cnt))

    logger.info("retrieving KEGG data")
    for pathway_id, pathway_desc, num_steps, disease, steps in fetch_kegg_data():
        cur.execute("INSERT INTO kegg VALUES (%s, %s, %s, %s)",
                    (pathway_id, pathway_desc, num_steps, disease))

        for uniprot_acc, hsa, gene, desc in steps:
            try:
                cur.execute("INSERT INTO kegg_step VALUES (%s, %s, %s, %s, %s)",
                            (pathway_id, uniprot_acc, hsa, gene, desc))
            except pymysql.err.IntegrityError:
                logger.warning("invalid mapping: {} <-> {}".format(pathway_id, uniprot_acc))

    logger.info("retrieving InterPro matches")
    with ThreadPoolExecutor(max_workers=args.threads) as executor:
        fs = {}
        for uniprot_acc in accessions:
            f = executor.submit(fetch_interpro_matches, uniprot_acc)
            fs[f] = uniprot_acc

        cnt = 0
        total = len(fs)
        while fs:
            failed = []
            for f in as_completed(fs):
                try:
                    entries = f.result()
                except Exception as exc:
                    # logger.debug("\terror: {}".format(exc))
                    failed.append(fs[f])
                else:
                    for interpro_acc, locations in entries:
                        for start, end in locations:
                            cur.execute("INSERT INTO interpro_match VALUES (%s, %s, %s, %s)",
                                        (interpro_acc, fs[f], start, end))

                    cnt += 1
                    if not cnt % 10000:
                        logger.debug("\t{:>6} / {}".format(cnt, total))

            fs = {}
            for uniprot_acc in failed:
                f = executor.submit(fetch_interpro_matches, uniprot_acc)
                fs[f] = uniprot_acc
        logger.debug("\t{:>6} / {}".format(cnt, total))

    con.commit()
    cur.close()
    con.close()

    logger.info("complete")


if __name__ == '__main__':
    main()
