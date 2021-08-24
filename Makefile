OBO = http://purl.obolibrary.org/obo

all: target all_obo neo.obo neo.owl

clean:
	rm trigger datasets.json mirror/*gz target/*.obo || echo "not all files present, perhaps last build did not complete"

TEST_SRCS ?= sgd pombase
SRCS ?= sgd pombase mgi zfin rgd dictybase fb tair wb goa_human goa_human_complex goa_human_rna goa_human_isoform goa_pig xenbase ecocyc pseudocap goa_sars-cov-2

OBO_SRCS = $(patsubst %,target/neo-%.obo,$(SRCS))
all_obo: $(OBO_SRCS)
test_obo: target $(patsubst %,target/neo-%.obo,$(TEST_SRCS))

#test: touch_trigger test_obo
test:
	echo "tests disabled until its easier to run perl on travis"

touch_trigger:
	touch trigger

trigger:
	touch $@

IMPORTS = imports/pr_import.obo
neo.obo:  $(OBO_SRCS) $(IMPORTS)
	owltools --create-ontology http://purl.obolibrary.org/obo/go/noctua/neo.owl $^ --merge-support-ontologies  -o -f obo $@.tmp && grep -v ^owl-axioms $@.tmp > $@



datasets.json: trigger
	wget http://s3.amazonaws.com/go-build/metadata/datasets.json -O $@ && touch $@


target:
	mkdir target

foo:
	pwd

# BUG: temporary hardcode until https://github.com/geneontology/go-site/issues/1431 is resolved and stable GPI URL is established
mirror/goa_sars-cov-2.gpi.gz:
	wget --no-check-certificate https://raw.githubusercontent.com/Knowledge-Graph-Hub/kg-covid-19/master/curated/ORFs/uniprot_sars-cov-2.gpi -O mirror/goa_sars-cov-2.gpi && gzip mirror/goa_sars-cov-2.gpi
target/neo-goa_sars-cov-2.obo: mirror/goa_sars-cov-2.gpi.gz
	gzip -dc $< | ./gpi2obo.pl -s Scov2 -n sars-cov-2 > $@.tmp && mv $@.tmp $@


# Sub-makefile
#
# contains targets:
#  - neo-{Gspe}.obo
#
# see below for regenerating this
include Makefile-gafs

# This is very hacky:
#  - The neo solr index has an ID field (which is a CURIE), but no URI
#  - Minerva requires OWL which uses URIs
#
# When loading solr, owltools will use the oboInOwl:id field as priority to load the ID field (see https://github.com/owlcollab/owltools/pull/247)
# Otherwise, the owltools built-in URI contraction method is used, which assumes OBO purls, with unpredictable behavior non-OBO PURLs
#
# Neo entities are NOT OBO ontologies, so they have a mix of prefixes, including identifiers.org
#
# Our hack is as follows. The perl code first generates an OBO file with CURIEs like FlyBase:FBgn111
# The default owltools expansion makes this an OBO PURLs
# We then "reverse" this with some hacky regexes...
neo.owl: neo.obo
	owltools $< -o $@.tmp && ./bin/fix-obo-uris.pl $@.tmp > $@.tmp2 && mv $@.tmp2 $@

Makefile-gafs: datasets.json
	./build-neo-makefile.py -i $< > $@.tmp && mv $@.tmp $@

GCRP=ftp://ftp.ebi.ac.uk/pub/contrib/goa/gcrp/

RNACFTP=ftp://ftp.ebi.ac.uk/pub/databases/RNAcentral/releases/3.0/genome_coordinates/

Homo_sapiens.GRCh38.gff3.gz:
	wget $(RNCFTP)/$@ -O $@


rnacentral.gpi.gz:
	wget ftp://ftp.ebi.ac.uk/pub/databases/RNAcentral/current_release/.gpi/rnacentral.gpi.gz

rnacentral.gpi: rnacentral.gpi.gz
	gzip -dc $< > $@

target/neo-rnac.obo: rnacentral.gpi.gz
	gzip -dc $< | ./rnacgpi2obo.pl > $@.tmp && mv $@.tmp $@

target/xneo-%.owl: target/neo-%.obo
	owltools $< -o $@.tmp && mv $@.tmp $@
target/neo-%.owl: target/xneo-%.owl
	./bin/fix-obo-uris.pl $< >  $@.tmp && mv $@.tmp $@
