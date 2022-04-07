#!/usr/bin/perl -w
####
#### Cheap script to filter out all the "known" species from the
#### collision-prone uniprot_reviewed file, as described in
#### https://github.com/geneontology/neo/issues/82#issuecomment-1074494641 .
####
#### Usage:
####   perl filter.pl -v --metadata /tmp/datasets.json --input /tmp/uniprot_reviewed.gpi > /tmp/clean_file.gpi
####
#### Makefile usage (ideal, if all things are in datasets.json):
####   perl filter.pl -v --metadata datasets.json --input mirror/uniprot_reviewed.gpi.tmp > mirror/filtered_uniprot_reviewed.gpi.tmp
####
#### Makefile usage (w/a list generated from grepping out all the non-reviews taxon):
####   perl filter.pl -v --metadata datasets.json --filter filter_list.txt --input mirror/uniprot_reviewed.gpi.tmp > mirror/filtered_uniprot_reviewed.gpi.tmp
####
#### This list can be generated by taking the uniprot_reviewed files
#### out of mirrors/ and: "zgrep -ohi 'taxon\:[0-9]*' *.gz | sort | uniq > /tmp/filter_list.txt"
####

## Bring in necessaries.
use utf8;
use strict;
use Data::Dumper;
use Getopt::Long;

## Opts.
my $verbose = '';
my $help = '';
my $metadata = '';
my $filter = '';
my $input = '';
GetOptions ('verbose' => \$verbose,
	    'help' => \$help,
	    'metadata=s' => \$metadata,
	    'filter=s' => \$filter,
	    'input=s' => \$input);

## Just a little easy printin' when feeling verbose.
sub ll {
  my $str = shift || '';
  print STDERR $str if $verbose;
}
ll("Verbose ON.\n");

## Embedded help through perldoc.
if( $help ){
  system('perldoc', __FILE__);
  exit 0;
}

###
### Main.
###

## Grab anything that looks like a taxon.
my %taxa_hash;
open(METADATA, '<', $metadata) or die "Cannot even open metadata: $metadata: $!";
while( <METADATA> ){
  ## We are going from NCBITaxon -> taxon.
  if( /NCBITaxon\:([0-9]+)/ ){
    $taxa_hash{'taxon:'. $1} = 1;
  }
}
close METADATA;

## Do the same for an optional test list file.
if( $filter ){
  open(FILTER, '<', $filter) or die "Cannot even open filter: $filter: $!";
  while( <FILTER> ){
    ## We are going from NCBITaxon -> taxon.
    if( /NCBITaxon\:([0-9]+)/ ){
      $taxa_hash{'taxon:'. $1} = 1;
    }
  }
}
close FILTER;

## Convert to something a little more usable.
my @taxa = keys(%taxa_hash);
# ## Force error for testing.
# push @taxa, 'taxon:399742';

## Check:
ll(Dumper \@taxa);

## Filter input file.
open(INPUT, '<', $input) or die "Cannot even open input: $input: $!";
while( <INPUT> ){
  #if( $_ ~~ @taxa ){
  my $line = $_;
  my $good_p = 1;
  for( @taxa ){
    if( $line =~ $_ ){
      ll('SKIPPING: '. $line);
      $good_p = 0;
      last;
    }
  }
  print STDOUT $line if $good_p;
}
close INPUT;

###
### Doc.
###

=head1 NAME

filter.pl

=head1 SYNOPSIS

filter.pl [-h/--help] [-v/--verbose] [-m/--metadata FILE] [-i/--input FILE]

=head1 DESCRIPTION

This script takes a datasets.json file (from the NEO pipeline--long story) and uses the taxon information in it to filter a GPI (or any other) file. Output to STDOUT.

Example usage:

perl filter.pl -v --metadata /tmp/datasets.json --input /tmp/uniprot_reviewed.gpi > /tmp/clean_file.gpi

=head1 OPTIONS

=over

=item -v/--verbose

Verbose

=item -h/--help

Help.

=item -m/--metadata FILE

The location of the datasets.json file.

=item -i/--input FILE

The location of the file to be filtered.

=back

=head1 SEE ALSO

https://github.com/geneontology/neo

=cut
