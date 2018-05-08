#!/usr/bin/perl -np
s@http://purl.obolibrary.org/obo/GR_protein_@http://identifiers.org/uniprot/@g;
s@http://purl.obolibrary.org/obo/(dictyBase|ZFIN|FB|WB|SGD|PomBase|RGD|MGI|Xenbase|UniProtKB|TAIR:\s+)_@"http://identifiers.org/".fix($1)."/"@eg;

sub fix {
    $s = lc($_[0]);
    $s =~ s@^fb$@flybase@;
    $s =~ s@^wb$@wormbase@;
    $s =~ s@^uniprotkb$@uniprot@;
    $s =~ s@^tair:@tair.@;
    return $s;
}

