#!/usr/bin/perl

use strict;

my $spn = 'generic';
my $fill_p = 0; # fill unknown species name with taxon id
my $ontid;
my $isoform_only = 0;

while (@ARGV) {
    my $opt = shift @ARGV;
    if ($opt eq '-s') {
        $spn = shift @ARGV;
    }
    elsif ($opt eq '-F') {
        $fill_p = 1;
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

print "ontology: go/noctua/$ontid\n";
print "\n";

my %done = ();
my $line_no=0;
my $gpi_version = '1.2';
while(<>) {
    chomp;
    $line_no++;
    if (m@^\!@) {
        if (m@^\!gpi-version: (\S+)@) {
            $gpi_version = $1;
        }
    }
    next if m@^\!@;

    my @vals = split(/\t/,$_, -1);
    my $N = scalar(@vals);
    if ($N < 7) {
        print STDERR "EXPECTED 10 COLS: $N :  $_\n";
        print STDERR "SKIPPING line $line_no: see https://github.com/geneontology/go-site/issues/595\n";
        next;
    }
    my ($db, $local_id, $symbol, $fullname, $syns_str, $type_str, $tax_id, $parent, $xrefs_str, $props) = @vals;
    if ($gpi_version =~ m@^2@) {
        my $global_id;
        ($global_id, $symbol, $fullname, $syns_str, $type_str, $tax_id, $parent, $xrefs_str, $props) = @vals;
        if ($global_id =~ m@^(\w+):(\S+)@) {
            ($db, $local_id) = ($1,$2);
        }
        else {
            die "incorrectly formatted id: $global_id";
        }
    }

    next unless $db;

    if ($local_id =~ m@^[\w:\-\.]+$@) {
    }
    else {
        print STDERR "BAD ID: $local_id\n";
        $local_id =~ s@[^\w:-]@-@g;
    }

    # Temporary, for reducing size of MGI file
    next if $db eq 'EMBL';
    next if $db eq 'ENSEMBL' && $local_id =~ m@ENSMUST@;

    my @syns = split(/\|/,$syns_str);
    my @xrefs = split(/\|/,$xrefs_str);

    # See: https://github.com/geneontology/noctua/issues/663
    push(@syns, $local_id);

    @syns = map {dequote($_)} @syns;
    $symbol = dequote($symbol);
    $fullname = dequote($symbol);

    my $id = $db eq 'MGI' ? $local_id : "$db:$local_id";

    $id = expand($id);

    next if $isoform_only && $id !~ m@\-\d+$@;

    if (!$symbol) {
        # RNAs coming from UniProt or RNCA lack symbols
        $symbol = $local_id;
    }

    $symbol =~ tr/a-zA-Z0-9\-_ \/\.//cd;

    $fullname =~ tr/a-zA-Z0-9\-_ \/\.//cd;

    if ($symbol eq $fullname) {
        $fullname = undef;
    }

    $tax_id =~ s/^taxon:/NCBITaxon:/;

    if( $fill_p ){
        $spn = $tax_id;
    }

    my $bltype = 'GeneProduct';
    my $type = 'CHEBI:33695 ! information biomacromolecule';
    if ($type_str eq 'protein') {
        $type = 'CHEBI:36080 ! protein';
        $bltype = 'Protein';
    }
    elsif ($type_str eq 'transcript') {
        $type = 'CHEBI:33697 ! ribonucleic acid';
        $bltype = 'RNAProduct';
    }
    elsif ($type_str eq 'protein_complex') {
        $type = 'GO:0032991 ! macromolecular complex';
        $bltype = 'MacromolecularComplex';
    }

    foreach my $x (@xrefs) {
        if ($x =~ m@:(\S+)@) {
            push(@syns, $1);
        }
    }


    print "[Term]\n";
    print "id: $id\n";
    print "name: $symbol $spn\n";
    print "synonym: \"$fullname $spn\" EXACT []\n" if $fullname && $fullname !~ m@homo sapiens@i;
    print "synonym: \"$symbol\" BROAD []\n";
    print "synonym: \"$_\" RELATED []\n" foreach @syns;
    print "xref: $_\n" foreach @xrefs;
    print "is_a: $type\n";
    print "relationship: in_taxon $tax_id\n";
    print "property_value: https://w3id.org/biolink/vocab/category https://w3id.org/biolink/vocab/MacromolecularMachine\n";
    print "property_value: https://w3id.org/biolink/vocab/category https://w3id.org/biolink/vocab/$bltype\n";
    if ($parent) {
        #$parent = expand($parent);
        print "relationship: has_gene_template $parent\n";
    }
    print "\n";

    $done{$id}++;
}

print "[Typedef]\n";
print "id: in_taxon\n";
print "xref: RO:0002162\n";


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

sub dequote {
    my $s = shift;
    $s =~ s@\"@\'@g;
    $s =~ s@\{@@g;
    return $s;
}
