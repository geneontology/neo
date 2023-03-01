#!/usr/bin/perl -np

# See https://github.com/identifiers-org/registry/issues/5
s@http://purl.obolibrary.org/obo/TAIR_locus%3A@http://identifiers.org/tair.locus/@g;

# gramene IDs are actually uniprot...
s@http://purl.obolibrary.org/obo/GR_protein_@http://identifiers.org/uniprot/@g;
s@http://purl.obolibrary.org/obo/dictyBase#_@http://identifiers.org/dictybase.gene/@g;
s@http://purl.obolibrary.org/obo/ComplexPortal_@https://www.ebi.ac.uk/complexportal/complex/@g;
s@http://purl.obolibrary.org/obo/RNAcentral#_@http://rnacentral.org/rna/@g;
# This substitution targets AGI_LocusCode IDs within literal values, forcing the oboInOwl:id field to be compacted.
# See https://github.com/geneontology/neo/issues/106
s@>http://purl.obolibrary.org/obo/AGI_LocusCode_@>AGI_LocusCode:@g;
# This script edits an XML file; thus the ampersand must be escaped
s@http://purl.obolibrary.org/obo/AGI_LocusCode_@http://arabidopsis.org/servlets/TairObject?type=locus&amp;name=@g;
# The optional hash in the match deals with some odd OWLAPI OBO parser behavior
s@http://purl.obolibrary.org/obo/(ZFIN|FB|WB|SGD|PomBase|RGD|MGI|Xenbase|UniProtKB|TAIR:\s+)#?_@"http://identifiers.org/".fix($1)."/"@eg;

s@http://identifiers.org/mgi/MGI%3A@http://identifiers.org/mgi/MGI:@g;

sub fix {
    $s = lc($_[0]);
    $s =~ s@^fb$@flybase@;
    $s =~ s@^wb$@wormbase@;
    $s =~ s@^uniprotkb$@uniprot@;
    $s =~ s@^tair:@tair.@;
    return $s;
}
