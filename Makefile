OBO = http://purl.obolibrary.org/obo

all: target all_ofn neo.obo neo.owl

clean:
	rm trigger datasets.json mirror/*gz mirror/*tmp target/*.obo || echo "not all files present, perhaps last build did not complete"

TEST_SRCS ?= sgd pombase
## WARNING: Changes make for #116
#SRCS ?= sgd pombase mgi zfin rgd dictybase fb tair wb goa_human goa_human_complex goa_human_rna goa_human_isoform goa_pig xenbase pseudocap ecocyc goa_sars-cov-2 goa_virus_bacteria_taxon_470 goa_virus_bacteria_taxon_12118 goa_virus_bacteria_taxon_253 goa_virus_bacteria_taxon_287 goa_virus_bacteria_taxon_545 goa_virus_bacteria_taxon_546 goa_virus_bacteria_taxon_548 goa_virus_bacteria_taxon_550 goa_virus_bacteria_taxon_562 goa_virus_bacteria_taxon_571 goa_virus_bacteria_taxon_573 goa_virus_bacteria_taxon_615 goa_virus_bacteria_taxon_623 goa_virus_bacteria_taxon_1313 goa_virus_bacteria_taxon_1352 goa_virus_bacteria_taxon_1353 goa_virus_bacteria_taxon_1390 goa_virus_bacteria_taxon_1392 goa_virus_bacteria_taxon_1901 goa_virus_bacteria_taxon_10254 goa_virus_bacteria_taxon_10255 goa_virus_bacteria_taxon_10298 goa_virus_bacteria_taxon_10335 goa_virus_bacteria_taxon_10359 goa_virus_bacteria_taxon_11251 goa_virus_bacteria_taxon_35703 goa_virus_bacteria_taxon_36352 goa_virus_bacteria_taxon_37734 goa_virus_bacteria_taxon_63746 goa_virus_bacteria_taxon_64320 goa_virus_bacteria_taxon_71421 goa_virus_bacteria_taxon_83333 goa_virus_bacteria_taxon_83334 goa_virus_bacteria_taxon_85962 goa_virus_bacteria_taxon_90371 goa_virus_bacteria_taxon_99287 goa_virus_bacteria_taxon_100226 goa_virus_bacteria_taxon_122586 goa_virus_bacteria_taxon_128958 goa_virus_bacteria_taxon_169963 goa_virus_bacteria_taxon_170187 goa_virus_bacteria_taxon_171101 goa_virus_bacteria_taxon_192222 goa_virus_bacteria_taxon_208964 goa_virus_bacteria_taxon_224308 goa_virus_bacteria_taxon_226185 goa_virus_bacteria_taxon_243273 goa_virus_bacteria_taxon_272558 goa_virus_bacteria_taxon_272634 goa_virus_bacteria_taxon_286636 goa_virus_bacteria_taxon_327105 goa_virus_bacteria_taxon_333760 goa_virus_bacteria_taxon_367830 goa_virus_bacteria_taxon_373153 goa_virus_bacteria_taxon_416870 goa_virus_bacteria_taxon_419947 goa_virus_bacteria_taxon_529507 goa_virus_bacteria_taxon_575584 goa_virus_bacteria_taxon_645098 goa_virus_bacteria_taxon_928302 goa_virus_bacteria_taxon_941280 goa_virus_bacteria_taxon_1125630
SRCS ?= sgd pombase mgi zfin rgd dictybase fb tair wb goa_human goa_human_complex goa_human_rna goa_human_isoform goa_pig xenbase pseudocap ecocyc goa_sars-cov-2 uniprot_reviewed

ROBOT_ENV = ROBOT_JAVA_ARGS=-Xmx12G
ROBOT = $(ROBOT_ENV) robot

OFN_SRCS = $(patsubst %,target/neo-%.ofn,$(SRCS))
all_ofn: $(OFN_SRCS)
test_ofn: target $(patsubst %,target/neo-%.ofn,$(TEST_SRCS))

#test: touch_trigger test_obo
test:
	echo "tests disabled until its easier to run perl on travis"

touch_trigger:
	touch trigger

trigger:
	touch $@

IMPORTS = imports/pr_import.obo
neo.owl: $(OFN_SRCS) $(IMPORTS)
	$(ROBOT) merge $(addprefix -i ,$^) annotate --ontology-iri 'http://purl.obolibrary.org/obo/go/noctua/neo.owl' convert -f owl -o $@.tmp && mv $@.tmp $@

## datasets.json is created as a throwaway in the NEO versions of the
## pipeline and is based on the go-site master data.
datasets.json: trigger
	wget http://s3.amazonaws.com/go-build/metadata/datasets.json -O $@ && touch $@


target:
	mkdir target

foo:
	pwd

# BUG: temporary hardcode until https://github.com/geneontology/go-site/issues/1431 is resolved and stable GPI URL is established
mirror/goa_sars-cov-2.gpi.gz:
	wget --no-check-certificate https://raw.githubusercontent.com/Knowledge-Graph-Hub/kg-covid-19/master/curated/ORFs/uniprot_sars-cov-2.gpi -O mirror/goa_sars-cov-2.gpi && gzip mirror/goa_sars-cov-2.gpi
target/neo-goa_sars-cov-2.ofn: mirror/goa_sars-cov-2.gpi.gz
	gzip -dc $< | ./gpi2ofn.pl -s Scov2 -n sars-cov-2 > $@.tmp && mv $@.tmp $@

# ## In support of including viruses and bacteria
# ## (https://github.com/geneontology/neo/issues/77).
# ## http://ftp.ebi.ac.uk/pub/contrib/goa/uniprot_reviewed_virus_bacteria.gpi.gz
# mirror/uniprot_reviewed_virus_bacteria.gpi.gz:
# 	wget --no-check-certificate http://ftp.ebi.ac.uk/pub/contrib/goa/uniprot_reviewed_virus_bacteria.gpi.gz -O mirror/uniprot_reviewed_virus_bacteria.gpi.gz
# target/neo-uniprot_reviewed_virus_bacteria.obo: mirror/uniprot_reviewed_virus_bacteria.gpi.gz
# 	gzip -dc $< | ./gpi2obo.pl -F -n reviewed_virus_bacteria > $@.tmp && mv $@.tmp $@

## In support of including all swissprot reviewed.
## Download and /filter out by species/.
## (https://github.com/geneontology/neo/issues/82).
## http://ftp.ebi.ac.uk/pub/contrib/goa/uniprot_reviewed.gpi.gz
## The filter_list.txt (and option) should not be needed in the future
## as we should be drawing exclusively from datasets.json.
mirror/uniprot_reviewed.gpi.gz: datasets.json
	wget --no-check-certificate http://ftp.ebi.ac.uk/pub/contrib/goa/uniprot_reviewed.gpi.gz -O mirror/uniprot_reviewed.gpi.gz.tmp
	gzip -dc mirror/uniprot_reviewed.gpi.gz.tmp > mirror/uniprot_reviewed.gpi.tmp
	perl filter.pl -v --metadata datasets.json --filter filter_list.txt --input mirror/uniprot_reviewed.gpi.tmp > mirror/filtered_uniprot_reviewed.gpi.tmp
	gzip -c mirror/filtered_uniprot_reviewed.gpi.tmp > mirror/filtered_uniprot_reviewed.gpi.gz.tmp
	mv mirror/filtered_uniprot_reviewed.gpi.gz.tmp mirror/uniprot_reviewed.gpi.gz
target/neo-uniprot_reviewed.ofn: mirror/uniprot_reviewed.gpi.gz
	gzip -dc $< | ./gpi2ofn.pl -F -n reviewed > $@.tmp && mv $@.tmp $@

# Sub-makefile
#
# contains targets:
#  - neo-{Gspe}.obo
#
# see below for regenerating this
include Makefile-gafs

#  The neo solr index has an ID field (which is a CURIE), but no URI
#  Minerva requires OWL which uses URIs
#
# When loading solr, owltools will use the oboInOwl:id field as priority to load the ID field (see https://github.com/owlcollab/owltools/pull/247)
# Otherwise, the owltools built-in URI contraction method is used, which assumes OBO purls, with unpredictable behavior non-OBO PURLs
neo.obo: neo.owl
	$(ROBOT) convert -i $< -o $@.tmp -f obo && grep -v ^owl-axioms $@.tmp >$@

Makefile-gafs: datasets.json
	./build-neo-makefile.py -i $< > $@.tmp && mv $@.tmp $@

GCRP=ftp://ftp.ebi.ac.uk/pub/contrib/goa/gcrp/

RNACFTP=ftp://ftp.ebi.ac.uk/pub/databases/RNAcentral/releases/3.0/genome_coordinates/

Homo_sapiens.GRCh38.gff3.gz:
	wget $(RNCFTP)/$@ -O $@


rnacentral.gpi.gz:
	wget ftp://ftp.ebi.ac.uk/pub/databases/RNAcentral/current_release/gpi/rnacentral.gpi.gz

rnacentral.gpi: rnacentral.gpi.gz
	gzip -dc $< > $@

target/neo-rnac.ofn: rnacentral.gpi.gz
	gzip -dc $< | ./rnacgpi2ofn.pl > $@.tmp && mv $@.tmp $@

target/neo-%.owl: target/neo-%.ofn
	$(ROBOT) convert -i $< -o $@.tmp -f owl && mv $@.tmp $@
