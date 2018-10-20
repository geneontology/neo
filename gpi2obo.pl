#!/usr/bin/perl

use strict;

my $spn = 'generic';
my $ontid;
my $isoform_only = 0;
my $is_uniprot = 0;

while (@ARGV) {
    my $opt = shift @ARGV;
    if ($opt eq '-s') {
        $spn = shift @ARGV;
    }
    elsif ($opt eq '-n') {
        $ontid = shift @ARGV;
    }
    elsif ($opt eq '--uniprot') {
        $is_uniprot = 1;
    }
    elsif ($opt eq '-I') {
        $isoform_only = 1;
    }
}
if (!$ontid) {
    $ontid = $spn;
}

our %uniprot_exclude = (
    # mammal
    '9606' => 1,
    '10090' => 1,

    '7955' => 1,
    '10116' => 1,
    '4896' => 1,
    '559292' => 1,
    '3702' => 1,
    '6239' => 1,
    
    # xenbase
    '8355' => 1,
    '8364' => 1,
    );

print "ontology: go/noctua/$ontid\n";
print "\n";

my %done = ();
my $line_no=0;
while(<>) {
    chomp;
    $line_no++;
    next if m@^\!@;

    my @vals = split(/\t/,$_);
    my $N = scalar(@vals);
    if ($N < 7) {
        print STDERR "EXPECTED 10 COLS: $N :  $_\n";
        print STDERR "SKIPPING line $line_no: see https://github.com/geneontology/go-site/issues/595\n";
        next;
    }
    my ($db, $local_id, $symbol, $fullname, $syns_str, $type_str, $tax_id, $parent, $xrefs_str, $props) = @vals;

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

    my $type = 'CHEBI:33695 ! information biomacromolecule';
    if ($type_str eq 'protein') {
        $type = 'CHEBI:36080 ! protein';
    }
    elsif ($type_str eq 'transcript') {
        $type = 'CHEBI:33697 ! ribonucleic acid';
    }

    foreach my $x (@xrefs) {
        if ($x =~ m@:(\S+)@) {
            push(@syns, $1);
        }
    }

    my $qsymbol = "$symbol $spn";
    my $qfullname = "$fullname $spn";
    if ($is_uniprot) {
        my $taxnum = $tax_id;
        if ($uniprot_exclude{$taxnum}) {
            next;
        }
        $taxnum =~ s@NCBITaxon:@@;
        $qsymbol + "$symbol sp:$taxnum";
        $qfullname + "$fullname sp:$taxnum";
    }
    
    print "[Term]\n";
    print "id: $id\n";
    print "name: $qsymbol\n";
    print "synonym: \"$qfullname\" EXACT []\n" if $fullname && $fullname !~ m@homo sapiens@i;
    print "synonym: \"$symbol\" BROAD []\n";
    print "synonym: \"$_\" RELATED []\n" foreach @syns;
    print "xref: $_\n" foreach @xrefs;
    print "is_a: $type\n";
    print "relationship: in_taxon $tax_id\n";
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
