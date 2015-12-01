#!/usr/bin/perl

use strict;

my $spn = 'generic';

while (@ARGV) {
    my $opt = shift @ARGV;
    if ($opt eq '-s') {
        $spn = shift @ARGV;
    }
}

my $is_rat = $spn eq 'Rnor';

print "ontology: go/noctua/$spn\n";
print "\n";

my %done = ();
while(<>) {
    chomp;
    next if m@^\!@;

    # RGD redundantly include annotations to UniProtKB, duplicating genes
    next if $is_rat && m@^UniProt@;

    my @vals = split(/\t/,$_);
    my $db = $vals[0];
    my $id = $db eq 'MGI' ? $vals[1] : "$db:$vals[1]";

    $id = expand($id);


    my $n = $vals[2];
    $n =~ tr/a-zA-Z0-9_//cd;
    my $type = $vals[11];
    my $taxid = $vals[12];
    $taxid =~ s/^taxon:/NCBITaxon:/;

    my $iso = $vals[16];

    if ($iso && $iso =~ /(\S+)\-(\d+)/) {
        my $num = $2;
        $iso =~ s/^PR:/UniProtKB:/;

        if (!$done{$iso}) {

            print "[Term]\n";
            print "id: $iso\n";
            print "name: $n isoform $num $spn\n";
            print "is_a: $id\n";
            #print "is_a: PR:000000001 ! protein\n";
            print "relationship: in_taxon $taxid\n";
            print "\n";

        }
        $done{$iso}++;
    }

    next if $done{$id};

    
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
