#!/usr/bin/perl

use strict;

my $spn = 'generic';

while (@ARGV) {
    my $opt = shift @ARGV;
    if ($opt eq '-s') {
        $spn = shift @ARGV;
    }
}

print "ontology: go/noctua/$spn\n";
print "\n";

my %done = ();
while(<>) {
    chomp;
    next if m@^\!@;
    my @vals = split(/\t/,$_);
    my $db = $vals[0];
    my $id = $db eq 'MGI' ? $vals[1] : "$db:$vals[1]";

    next if $done{$id};

    my $n = $vals[2];
    $n =~ tr/a-zA-Z0-9_//cd;
    my $type = $vals[11];
    my $taxid = $vals[12];
    $taxid =~ s/^taxon:/NCBITaxon:/;
    
    print "[Term]\n";
    print "id: $id\n";
    print "name: $n $spn\n";
    print "synonym: \"$n\" BROAD []\n";
    print "is_a: CHEBI:23367 ! molecular entity\n";
    print "relationship: in_taxon $taxid\n";
    print "\n";

    $done{$id}++;
}

print "[Typedef]\n";
print "id: in_taxon\n";
print "xref: RO:0002162\n";


# PR:000000001 ! protein
