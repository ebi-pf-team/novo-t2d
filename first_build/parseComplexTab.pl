#!/usr/bin/env perl

use strict;
use warnings;
use File::Slurp;

my @complexes = read_file("database_in_files/homo_sapiens.tsv");

foreach my $c (@complexes){
  my @fields = split(/\t/, $c);
  my $proteins = split(/\|/, $fields[4]);
  my $line = join("\t", $fields[0], $fields[1], $proteins, $fields[4]);
  print "$line\n";
}


