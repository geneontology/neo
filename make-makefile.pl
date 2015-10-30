#!/usr/bin/perl
use strict;
my %smap = (
    Scer => 'sgd'
    );

foreach (keys %smap) {
    my $n = $smap{$_};
    print "neo-$_.obo: $n.gaf.gz\n";
    print "\tgzip -dc \$< | gaf2obo.pl -s $_ > \$@.tmp && mv \$@.tmp \$@\n\n";
    
}
