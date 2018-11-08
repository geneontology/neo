OBO = http://purl.obolibrary.org/obo

all: target all_obo neo.obo neo.owl

clean:
	rm trigger datasets.json mirror/*gz target/*.obo || echo "not all files present, perhaps last build did not complete"

TEST_SRCS = sgd pombase
SRCS = sgd pombase mgi zfin rgd dictybase fb tair wb gramene_oryza goa_human goa_human_complex goa_human_rna goa_human_isoform goa_pig xenbase

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
	wget http://s3.amazonaws.com/go-public/metadata/datasets.json -O $@ && touch $@


target:
	mkdir target

foo:
	pwd

# Sub-makefile
#
# contains targets:
#  - neo-{Gspe}.obo
#
# see below for regenerating this
include Makefile-gafs

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

target/neo-swissprot_gcrp.obo:
	curl -L ftp://ftp.ebi.ac.uk/pub/databases/GO/goa/UNIPROT/goa_uniprot_gcrp.gpi.gz | gzip -dc  | grep 'db_subset=Swiss-Prot' | ./gpi2obo.pl -t meta/taxnames.tsv --uniprot -n swissprot_gcpr > $@.tmp && mv $@.tmp $@


target/neo-rnac.obo: rnacentral.gpi.gz 
	gzip -dc $< | ./rnacgpi2obo.pl > $@.tmp && mv $@.tmp $@

target/xneo-%.owl: target/neo-%.obo
	owltools $< -o $@.tmp && mv $@.tmp $@
target/neo-%.owl: target/xneo-%.owl
	./bin/fix-obo-uris.pl $< >  $@.tmp && mv $@.tmp $@

