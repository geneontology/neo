#!/usr/bin/perl

use strict;

our @taxa = qw(
10090
10116
3702
39947
44689
4530
4896
559292
6239
7227
7955
9606
);

my %tm = map {($_=>1)} @taxa;

open my $fh, '<', 'prefixes.obo.txt' or die "error opening prefixes.obo.txt: $!";
my $prefixes = do { local $/; <$fh> };

print "format-version: 1.2\n";
print $prefixes;
print "ontology: go/noctua/rnac\n";
print "\n";

my %done = ();
while(<>) {
    chomp;
    next if m@^\!@;

    my @vals = split(/\t/,$_);
    print STDERR "BAD: $_\n" unless $vals[5] eq 'rna';
    
    my $id = $vals[0] . ":" . $vals[1];
    $id =~ s/_/-/;
    my $n = $vals[3];
    my $taxid = $vals[6];
    $taxid =~ s/taxon://;
    #print STDERR "$taxid\n";
    next unless $tm{$taxid};

    print "[Term]\n";
    print "id: $id\n";
    print "name: $n\n";
    print "synonym: \"$n\" BROAD []\n";
    print "is_a: CHEBI:33697 ! ribonucleic acid\n";
    print "relationship: in_taxon NCBITaxon:$taxid\n";
    print "\n";

    $done{$id}++;
}

print "[Typedef]\n";
print "id: in_taxon\n";
print "xref: RO:0002162\n";


# PR:000000001 ! protein
exit 0;
