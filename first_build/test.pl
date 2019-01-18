#!/usr/bin/env perl

use strict;
use warnings;
use File::Slurp;

my @iprMatches = read_file("database_in_files/interpro_match.tsv");
foreach my $m (@iprMatches){
  chomp($m);
  my @fields = split(/\t/, $m);
  print "$fields[1]\n" if($fields[1] !~ /\S+/);
}
