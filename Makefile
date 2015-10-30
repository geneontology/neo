
all: all_obo neo.obo neo.owl

test: touch_trigger all_obo

touch_trigger:
	touch trigger

trigger:
	touch $@

%.gaf.gz: trigger
	wget http://geneontology.org/gene-associations/gene_association.$*.gz -O $@ && touch $@

include Makefile-gafs

neo.owl: neo.obo
	owltools $< -o $@

Makefile-gafs:
	./make-makefile.pl > $@.tmp && mv $@.tmp $@
