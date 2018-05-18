#!/usr/bin/perl -np

# See https://github.com/identifiers-org/registry/issues/5
s@http://purl.obolibrary.org/obo/TAIR_locus%3A@http://identifiers.org/tair.locus/@g;

# gramene IDs are actually uniprot...
s@http://purl.obolibrary.org/obo/GR_protein_@http://identifiers.org/uniprot/@g;
s@http://purl.obolibrary.org/obo/dictyBase#_@http://identifiers.org/dictybase.gene/@g;
s@http://purl.obolibrary.org/obo/(ZFIN|FB|WB|SGD|PomBase|RGD|MGI|Xenbase|UniProtKB|TAIR:\s+)_@"http://identifiers.org/".fix($1)."/"@eg;

sub fix {
    $s = lc($_[0]);
    $s =~ s@^fb$@flybase@;
    $s =~ s@^wb$@wormbase@;
    $s =~ s@^uniprotkb$@uniprot@;
    $s =~ s@^tair:@tair.@;
    return $s;
}

