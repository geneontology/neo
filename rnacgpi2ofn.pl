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

open my $fh, '<', 'prefixes.ofn.txt' or die "error opening prefixes.obo.txt: $!";
my $prefixes = do { local $/; <$fh> };

print "format-version: 1.2\n";
print $prefixes;
print "Ontology(<http://purl.obolibrary.org/obo/go/noctua/rnac.owl>\n";
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

    print "AnnotationAssertion(rdfs:label $n\")\n";
    print "AnnotationAssertion(oboInOwl:hasBroadSynonym $n\")\n";
    print "SubClassOf($id CHEBI:33697)\n";
    print "SubClassOf($id ObjectSomeValuesFrom(obo:RO_0002162 $taxid))\n";
    print "\n";

    $done{$id}++;
}


print ")\n";


# PR:000000001 ! protein
exit 0;
