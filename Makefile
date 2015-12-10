
all: all_obo neo.obo neo.owl
test: all

test: touch_trigger all_obo

touch_trigger:
	touch trigger

trigger:
	touch $@

%.gaf.gz: trigger
	wget http://geneontology.org/gene-associations/gene_association.$*.gz -O $@ && touch $@

goa_merged_human.gaf.gz: goa_ref_human.gaf.gz goa_human.gaf.gz
	gzip -dc goa_ref_human.gaf.gz > tmp1 &&\
	gzip -dc goa_human.gaf.gz | grep ^RNAcentral > tmp2 &&\
	cat tmp1 tmp2 > goa_merged_human.gaf &&\
	gzip goa_merged_human.gaf


include Makefile-gafs

neo.owl: neo.obo
	owltools $< -o $@

Makefile-gafs:
	./make-makefile.pl > $@.tmp && mv $@.tmp $@

RNACFTP=ftp://ftp.ebi.ac.uk/pub/databases/RNAcentral/releases/3.0/genome_coordinates/

Homo_sapiens.GRCh38.gff3.gz:
	wget $(RNCFTP)/$@ -O $@
