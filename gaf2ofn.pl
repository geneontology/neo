#!/usr/bin/perl

use strict;

my $spn = 'generic';
my $ontid;
my $isoform_only = 0;
open my $fh, '<', 'prefixes.ofn.txt' or die "error opening prefixes.obo.txt: $!";
my $prefixes = do { local $/; <$fh> };

while (@ARGV) {
    my $opt = shift @ARGV;
    if ($opt eq '-s') {
        $spn = shift @ARGV;
    }
    elsif ($opt eq '-n') {
        $ontid = shift @ARGV;
    }
    elsif ($opt eq '-I') {
        $isoform_only = 1;
    }
}
if (!$ontid) {
    $ontid = $spn;
}

my $is_rat = $spn eq 'Rnor';

print $prefixes;
print "Ontology(<http://purl.obolibrary.org/obo/go/noctua/$ontid.owl>\n";
print "\n";

my %done = ();
while(<>) {
    chomp;
    next if m@^\!@;

    # RGD redundantly include annotations to UniProtKB, duplicating genes
    next if $is_rat && m@^UniProt@;

    my @vals = split(/\t/,$_);
    my $db = $vals[0];
    my $local_id = $vals[1];
    my $id = $db eq 'MGI' ? $local_id : "$db:$local_id";

    $id = expand($id);

    next if $isoform_only && $id !~ m@\-\d+$@;
    
    
    my $n = $vals[2];
    $n =~ tr/a-zA-Z0-9\-_//cd;

    my $fullname = $vals[9];
    $fullname =~ tr/a-zA-Z0-9\- //cd;

    if ($n eq $fullname) {
        $fullname = undef;
    }

    my @syns = split(/\|/,$vals[10]);
    
    # See: https://github.com/geneontology/noctua/issues/663
    push(@syns, $local_id);

    my $type_str = $vals[11];

    my $bltype = 'GeneProduct';
    my $type = 'CHEBI:33695'; #information biomacromolecule

    # note some groups incorrectly classify their genes as proteins
    #if ($type_str eq 'protein') {
    #    $type = 'CHEBI:36080'; #protein
    #    $bltype = 'Protein';
    #}
    if ($type_str eq 'transcript') {
        $type = 'CHEBI:33697'; #ribonucleic acid
        $bltype = 'RNAProduct';
    }
    if ($type_str eq 'protein_complex') {
        $type = 'GO:0032991'; #macromolecular complex
        $bltype = 'MacromolecularComplex';
    }
    
    
    my $taxid = $vals[12];
    $taxid =~ s/^taxon:/NCBITaxon:/;

    my $iso = $vals[16];

    if ($iso && $iso =~ /(\S+)\-(\d+)/) {
        my $num = $2;
        $iso =~ s/^PR:/UniProtKB:/;

        if (!$done{$iso}) {

            print "AnnotationAssertion(rdfs:label $iso \"$n isoform $num $spn\")\n";
            print "AnnotationAssertion(biolink:category $id biolink:MacromolecularMachine)\n";
            print "AnnotationAssertion(biolink:category $id biolink:GeneProductIsoform)\n";
            print "SubClassOf($iso $id)\n";
            print "SubClassOf($id ObjectSomeValuesFrom(obo:RO_0002162 $taxid))\n";
            print "\n";

        }
        $done{$iso}++;
    }

    next if $done{$id};

    if ($n =~ m@(.*)_(\d+)$@) {
        my ($n2,$ntaxid) = ($1,$2);
        if ($taxid eq "NCBITaxon:$ntaxid") {
            $n =~ s@_\d+$@@;
        }
    }
    
    print "AnnotationAssertion(rdfs:label $id \"$n $spn\")\n";
    print "AnnotationAssertion(oboInOwl:hasExactSynonym $id \"$fullname $spn\")\n"  if $fullname && $fullname !~ m@homo sapiens@i;
    print "AnnotationAssertion(oboInOwl:hasBroadSynonym $id \"$n\")\n";
    print "AnnotationAssertion(biolink:category $id biolink:MacromolecularMachine)\n";
    print "AnnotationAssertion(biolink:category $id biolink:$bltype)\n";
    print "SubClassOf($id $type)\n";
    print "SubClassOf($id ObjectSomeValuesFrom(obo:RO_0002162 $taxid))\n";
    if ($parent) {
        #$parent = expand($parent);
        print "SubClassOf($id ObjectSomeValuesFrom(neo:has_gene_template $parent))\n";
    }
    print "\n";

    $done{$id}++;
}


print ")\n";


# PR:000000001 ! protein
exit 0;

# todo: derive this from CURIE map
sub expand {
    my $id = shift;
    $_ = $id;
    #s@^MGI:@http://www.informatics.jax.org/accession/MGI:@;

    # perpetuate MGI awfulness for now
    s@^MGI:@MGI:MGI:@;
    return $_;
}
