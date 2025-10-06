[![Build Status](https://travis-ci.org/geneontology/neo.svg?branch=master)](https://travis-ci.org/geneontology/neo)

# Noctua Entity Ontology

This repository contains classes required by Noctua/Minerva for
representing entities that are object of 'enabled by' relations, and
similar molecular relationships. This includes:

 * genes
 * protein (gene-level generic proteins and isoforms)
 * functional RNAs
 * complexes

These are represented as ontology _classes_, although NEO is not
really an ontology in a conventional sense: there is no hierarchy, it
is organized as a largely flat list. The purpose of distributing as an
ontology is:

 * Noctua is ontology-driven; curated create links between __instances__ of classes
 * RDF/OWL is the lingua-franca of the Noctua framework, and avoids the need for an ad-hoc format
 * We can use reasoning to determine if relationships are valid

the GO Noctua instances loads the ontology
[go-lego.owl](http://purl.obolibrary.org/obo/go/extensions/go-lego.owl),
which imports NEO

# Availability

This GitHub repository only contains the tools required to build
neo. The ontology is available from the following PURLS (Permanent URLs):

 * http://purl.obolibrary.org/obo/go/noctua/neo.obo
 * http://purl.obolibrary.org/obo/go/noctua/neo.owl

The build is handled by
[build-noctua-entity-ontology](https://build.berkeleybop.org/job/build-noctua-entity-ontology/)
on Jenkins.

This runs the [Makefile](Makefile) in this repository, and deploys the
resulting ontology on S3, where it is available in multiple regions
via cloudfront.

# Contents (abstract)

The contents of NEO are largely driven by the contents of each GOC
member's GPI file (if a GPI file is not provided, a GAF is used
instead). This allows each MOD or Database to have control over what
kinds of entities can and cannot be described in Noctua.

The procedure for building NEO is relatively straightforward. The
process is entirely automated, and no curation is involved. See the
[Makefile](Makefile) for details, but the overall procedure is:

 * [GOC datasets metadata](https://github.com/geneontology/go-site/tree/master/metadata/datasets) is downloaded
 * for each database contributing, the metadata is searched first for a GPI; if not present a GAF is used
 * A simple script is executed converting the GAF or GPI into an ontology for that database/species
 * The results are concatenated together into neo.obo / neo.owl

For modeling choices, we aim to be consistent with other ontologies
such as PRO. For example, the `parent` column in a GPI is used to make
`has_gene_template` relationships between the protein and its gene.

For genes we populate the UniProt Xref as a synonym to enhance
autocomplete, and similarly gene IDs for proteins. This is to make it
easier to select the correct entity type (typically a protein) for GOC
members who are gene-centric.

Currently, the MGI GPI file uses PRO for protein entities, whereas the
human GPI uses UniProtKB IDs. This means that a Noctua user can use
PRO for mouse and UniProt for human.

# Contents (developer)

At the top level, the biological entity contents of NEO are mainly defined from the http://s3.amazonaws.com/go-build/metadata/datasets.json file. This file, in turn, is generated from `metadata/datasets/*.yaml` in the `go-site` repo when the NEO pipeline runs every week.

This is filtered against the `SRCS` variable in the `Makefile` in this repo, currently (2025-06-30) defined as:

`SRCS ?= sgd pombase mgi zfin rgd dictybase fb tair wb goa_human goa_pig xenbase pseudocap ecocyc goa_sars-cov-2 uniprot_reviewed goa_virus_bacteria_taxon_545 goa_virus_bacteria_taxon_574 goa_virus_bacteria_taxon_623 goa_virus_bacteria_taxon_1353 goa_virus_bacteria_taxon_1392 goa_virus_bacteria_taxon_1901 goa_virus_bacteria_taxon_10254 goa_virus_bacteria_taxon_10299 goa_virus_bacteria_taxon_10338 goa_virus_bacteria_taxon_10360 goa_virus_bacteria_taxon_63746 goa_virus_bacteria_taxon_64320 goa_virus_bacteria_taxon_71421 goa_virus_bacteria_taxon_83334 goa_virus_bacteria_taxon_85962 goa_virus_bacteria_taxon_93061 goa_virus_bacteria_taxon_99287 goa_virus_bacteria_taxon_100226 goa_virus_bacteria_taxon_122586 goa_virus_bacteria_taxon_169963 goa_virus_bacteria_taxon_170187 goa_virus_bacteria_taxon_171101 goa_virus_bacteria_taxon_192222 goa_virus_bacteria_taxon_208964 goa_virus_bacteria_taxon_224308 goa_virus_bacteria_taxon_226185 goa_virus_bacteria_taxon_243273 goa_virus_bacteria_taxon_272558 goa_virus_bacteria_taxon_272634 goa_virus_bacteria_taxon_295027 goa_virus_bacteria_taxon_301447 goa_virus_bacteria_taxon_327105 goa_virus_bacteria_taxon_333760 goa_virus_bacteria_taxon_373153 goa_virus_bacteria_taxon_419947 goa_virus_bacteria_taxon_565655 goa_virus_bacteria_taxon_575584 goa_virus_bacteria_taxon_587200 goa_virus_bacteria_taxon_645098 goa_virus_bacteria_taxon_928302 goa_virus_bacteria_taxon_1125630`

In addition, the following exceptions/additions are made:

- `goa_sars-cov-2`: https://raw.githubusercontent.com/Knowledge-Graph-Hub/kg-covid-19/master/curated/ORFs/uniprot_sars-cov-2.gpi
- `uniprot_reviewed`: http://ftp.ebi.ac.uk/pub/contrib/goa/uniprot_reviewed.gpi.gz (filtered)

# FAQ/TODO

See the issue tracker for full TODOs

## RNAs

RNAs come in via RNA central; we are still tweaking the pipeline, see issue tracker for details

## Use of Gene IDs within Noctua

Currently the OWL models produced by Noctua use gene entities (from
MGI, WB, etc) as the endpoint of `enabled_by` relationships. Note that
this is semantically incorrect, as this relationship type should be
used in conjunction with the molecule that has the activity, ie the
protein.

This was a short term decision to get us off the ground. Originally we
chose to interpret the MOD Gene ID `X` as the `owl:unionOf` (a) the
gene denoted by `X` (b) any gene product that is `encoded_by` some
`X`. However, this was found to be confusing and problematic.

Moving forward, the decision is to use the correct entity type at all
times. Thus the majority of the time the `enabled_by` will link to a
protein (or sometimes an ncRNA). One concern was that for MODs, it can
be difficult to select a protein ID that is guaranteed to permanently
have the desired semantics of "any product of gene X". To help, we:

 * ensure that the gene ID is present as a synonym in the corresponding protein class, to facilitate accurate selection
 * allow MODs control over what protein IDs are used via their GPI files. Thus if a MOD uses their own MOD protein IDs, these can be used. Alternatively the MOD can choose UniProt or PRO

At some stage we will switch out existing gene IDs for designated protein IDs.

The above applies to the scenario whereby the curator wants to
describe activity for a generic product of a gene, and does not want
to select a specific isoform (either because the function is believed
to be held by all isoforms, or because isoform-level information is
not known). Of course, when isoform level information is known, an
isoform ID should be used. Again, this is under control of the
contributing database via their GPI.

There are many subtleties here, but briefly:

 * we use the UniProtKB GCPR entry to denote the generic entry (what PRO calls organism-gene-level)
 * In a handful of cases, e.g. GNAS, there are multiple swissprot entries but only one GCPR. See below

## Relationship to PRO

NEO is generated automatically from GPIs, whereas PRO has a large
curated component. However, in many cases they will have the same
content. In particular, MGI provides lines in their GPI file that come
from PRO, so we are in effect reconstituting PRO for the mouse subset.

PRO will largely overlap with UniProtKB. There are some subtle
differences - see for example the representation of GNAS in human and
mouse. Here guidelines may vary by database. For mouse, where PRO is
used, the curator has access to precise semantics - either the
organism-gene-level entry can be used, or a grouping isoform can be
used.

## Build frequency

Currently NEO builds are manually triggered.

## Troubleshooting

Sometimes it can be difficult to figure out what's going on with the
build. For those interested in understanding the build of a single resource target (e.g. mgi.gpi -> mgi-neo.obo), the following command can be useful:

`make clean && TEST_SRCS=mgi make test_ofn 2>&1 | tee /tmp/log.txt`
