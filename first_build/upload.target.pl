#!/usr/bin/env perl

use strict;
use warnings;
use File::Slurp;
use DDP;
use Text::CSV;

use NovoNordiskDB;


#Connect to the database
my $dbi_dsn = "dbi:mysql:database=novonordisk;host=127.0.0.1;";
my $user = 'root';
my $pass = undef;
my %dbi_params;
my $schema = NovoNordiskDB->connect($dbi_dsn, $user, $pass, \%dbi_params);


my %seen;
my @proteins = read_file("database_in_files/Protein/ProteinForHumanWithKO.tab");
my @targets = read_file("database_in_files/Target_updated_reducedEFOs");

#Updated
my $doneProtein = 1;
foreach my $p (@proteins){
  chomp($p);
  next if($p =~ /^Entry/); #Remove header line.
  
  my @fields = split(/\t/, $p);
  $fields[4] =~ s/^"//;
  $fields[4] =~ s/"$//;

  $seen{$fields[0]}++;
  
}

#Checked
foreach my $t (@targets){
  chomp($t);
  next if($t =~ /^uniprot/);
  my @fields = split(/\t/, $t);
  if(!defined($seen{$fields[0]})){
    warn "$fields[0] is not in the protein table, skipping target\n$t";
    next;
  }
  if($fields[1] =~ /Drug/){
    $fields[1] = "CHEMBL";
  }
  foreach my $s (split(/\//, $fields[1])){
  my $row =
    $schema->resultset('Target')->update_or_create( 'uniprot_acc' => $fields[0],
                                                    'source'      => $s,
                                                    'disease'     => $fields[2],
                                                    'efo_id'      => $fields[3],
                                                    'target_type' => $fields[4] );
  }
}


