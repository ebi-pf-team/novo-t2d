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
my @secreted = read_file("database_in_files/Secretome/UniProtSignalSecreted.tab");
my @targets = read_file("database_in_files/Target");
my @transcripts = read_file("database_in_files/Ensembl/UniprotHumanEnsembl.tab");
my @structures = read_file("database_in_files/PDB/pdb_chain.txt");
my @ipr = read_file("database_in_files/interpro.tsv");
my @iprMatches = read_file("database_in_files/interpro_match.tsv");
my @go = read_file("database_in_files/GO/UniProtWithGOterms.tab");
my @cp = read_file("database_in_files/Complex_portal");
my @complexes = read_file("database_in_files/complex_homo_sapiens.tsv");
my @ho = read_file("database_in_files/Orthology/HumanWithKO.tab");
my @mo = read_file("database_in_files/Orthology/MouseWithKO.tab");
my @kegg = read_file("database_in_files/KEGG/kegg");
my @kegg_step = read_file("database_in_files/KEGG/kegg_step");

my %secreted;
foreach my $s (@secreted){
  chomp($s);
  my @fields = split(/\t/, $s);
  $secreted{$fields[0]}++;
}

#Updated
my $doneProtein = 1;
foreach my $p (@proteins){
  chomp($p);
  next if($p =~ /^Entry/); #Remove header line.
  
  my @fields = split(/\t/, $p);
  $fields[4] =~ s/^"//;
  $fields[4] =~ s/"$//;

  if($doneProtein != 1){
  my $row = 
  $schema->resultset('Protein')->update_or_create( 'uniprot_acc'          => $fields[0],
                                                   'uniprot_id'           => $fields[1],
                                                   'reviewed'             => $fields[2] eq "unreviewed" ? 0 : 1,
                                                   'gene_name'            => defined($fields[3]) ? $fields[3] : undef,
                                                   'description'          => $fields[4],
                                                   'species'              => $fields[5],
                                                   'ensembl_gene'         => $fields[6],
                                                   'complex_portal_xref'  => $fields[7],
                                                   'reactome_xref'        => $fields[8],
                                                   'kegg_xref'            => $fields[9],
                                                   'proteome'             => $fields[11],
                                                   'secreted'             => defined($secreted{$fields[0]}) ? 1 : 0);
  }
  $seen{$fields[0]}++;
  
}

my $doneKegg = 0;

if(!$doneKegg){
  my %kp;
  #Load the kegg pathways
  foreach my $k (@kegg){
    chomp($k);
    my @fields = split(/\t/, $k);
    $schema->resultset('Kegg')->update_or_create( 'kegg_pathway_id' => $fields[0],
                                                  'description'     => $fields[1],
                                                  'number_steps'    => $fields[2]);
    $kp{$fields[0]}++;
  }

  foreach my $ks (@kegg_step){

    chomp($ks);
    my @fields = split(/\t/, $ks);
    

    if(!defined($seen{$fields[1]})){
      warn "$fields[1] is not in the protein table, skipping kegg step\n$ks";
      next;
    }
    if(!defined($kp{$fields[0]})){
      warn "$fields[0] is not in the kegg table, skipping kegg step\n$ks";
      next;
    }

    $schema->resultset('KeggStep')->update_or_create( 'kegg_pathway_id'   => $fields[0],
                                                      'uniprot_acc'       => $fields[1],
                                                      'kegg_protein'      => $fields[2],
                                                      'kegg_gene'         => $fields[3],
                                                      'kegg_protein_desc' => $fields[4] );

  }

}

exit;



my $doneGo = 1;

if($doneGo != 1){
  print STDERR "GO table\n";
foreach my $g (@go){
  chomp($g);
  my @fields = split(/\t/, $g);
  
  if(!defined($seen{$fields[0]})){
    warn "$fields[0] is not in the protein table, skipping match\n$g";
    next;
  }
  
  if(defined($fields[3]) and $fields[3] =~ /\S+/){
    #MF
    my @mf = split(/\;/, $fields[3]);
    foreach my $mf ( @mf) {
        if($mf =~ /(.*) \[(GO\:\d+)\]/){
          my $go_id = $2;
          my $go_name = $1;
          $schema->resultset('GeneOntology')->update_or_create( 'uniprot_acc' => $fields[0],
                                                                'go_id'       => $go_id,
                                                                'go_class'    => 'MF',
                                                                'go_name'     => $go_name);
        }
    }
  }
  if(defined($fields[4]) and $fields[4] =~ /\S+/){
    #BP
    my @bp = split(/\;/, $fields[4]);
    foreach my $bp ( @bp) {
        if($bp =~ /(.*) \[(GO\:\d+)\]/){
          my $go_id = $2;
          my $go_name = $1;
          $schema->resultset('GeneOntology')->update_or_create( 'uniprot_acc' => $fields[0],
                                                                'go_id'       => $go_id,
                                                                'go_class'    => 'BP',
                                                                'go_name'     => $go_name);
        }
    }
  }
  
  if(defined($fields[5]) and $fields[5] =~ /\S+/){
    #CC
    my @cc = split(/\;/, $fields[5]);
    foreach my $cc ( @cc) {
        if($cc =~ /(.*) \[(GO\:\d+)\]/){
          my $go_id = $2;
          my $go_name = $1;
          $schema->resultset('GeneOntology')->update_or_create( 'uniprot_acc' => $fields[0],
                                                                'go_id'       => $go_id,
                                                                'go_class'    => 'CC',
                                                                'go_name'     => $go_name);
        }
    }
  }
}
}



my $doneOrtho = 1;

if($doneOrtho != 1){
print STDERR "Orthology\n";

my %orthosH;
foreach my $ho (@ho){
  chomp($ho);
  my @f = split(/\t/, $ho);
  if(!defined($seen{$f[0]})){
    warn "$f[0] is not in the protein table, skipping ortholog information\n$ho";
    next;
  }
  $f[2] =~ s/\;//;
  push(@{$orthosH{$f[2]}},$f[0]);
}

foreach my $mo (@mo){
  chomp($mo);
  my @f = split(/\t/, $mo);
  $f[2] =~ s/\;//;
  if($orthosH{$f[2]}){
    foreach my $acc (@{ $orthosH{$f[2]} }){
      $schema->resultset('Ortholog')->update_or_create( 'uniprot_acc' => $acc,
                                                        'ortholog_uniprot_acc' => $f[0],
                                                        'species' => 10090);
    }
  } 
}
}



my $doneReactome = 1;

if($doneReactome != 1){
print STDERR "Reactome\n";

my %seenR;
my $csv = Text::CSV->new ( { binary => 1,    
                             sep_char        => "\t",
                              eol             => "\n",
    quote_space     => 0,
    quote_null      => 0, } )  # should set binary attribute.
                        or die "Cannot use CSV: ".Text::CSV->error_diag ();

open my $fh, "<:encoding(utf8)",
  "database_in_files/Reactome/PathwayDescriptionStepcountSpecies.txt"
  or die
  "reactome PathwayDescriptionStepcountSpecies.txt could not be opened: $!";
while ( my $row = $csv->getline( $fh ) ) {
  next if($row->[0] =~ /pathwayId/);
  $schema->resultset('Reactome')->update_or_create( 'pathway_id'  => $row->[0],
                                                    'description' => $row->[1],
                                                    'number_steps'=> $row->[2],
                                                    'species'     => $row->[3]);
  $seenR{$row->[0]}++;
}
$csv->eof or $csv->error_diag();
close $fh;





open $fh, "<:encoding(utf8)", "database_in_files/Reactome/reactome_step.txt" or die "reactome_step.txt: $!";
        while ( my $row = $csv->getline( $fh ) ) {
        
        
          if(!defined($seen{$row->[1]})){
            #warn $row->[1]." is not in the protein table, skipping reactome step\n";
            next;
          }

  if(!defined($seenR{$row->[0]})){
    if($row->[0] ne "#N/A"){
      warn $row->[0]." is not in the reactome table, skipping reactome step\n";
    }
    next;
  }
  
  $schema->resultset('ReactomeStep')->find_or_create( 'pathway_id'  => $row->[0],
                                                        'uniprot_acc' => $row->[1],
                                                        'reaction_id' => $row->[2],
                                                        'reaction_description' => $row->[3]);
        
        
        }
        $csv->eof or $csv->error_diag();
        close $fh;

}

#Checked
my %complexes;
my $doneComplexes = 1;

if($doneComplexes != 1){
foreach my $c (@cp){
  chomp($c);
  my ($u, $cp) = split(/\s+/, $c);
  push(@{ $complexes{$cp} }, $u);
}


#Checked, using old file
foreach my $c (@complexes){
  chomp($c);
  my @fields = split(/\t/, $c);

  next unless($complexes{$fields[0]});
  my $proteins = split(/\|/, $fields[4]);
  
  $schema->resultset('ComplexPortal')->update_or_create( "complex_portal_accession" => $fields[0],
                                                          "description"             => $fields[1],
                                                          "number_proteins"         => $proteins   );

  foreach my $p (@{$complexes{$fields[0]}}){
    if(!defined($seen{$p})){
      warn "$p in complex $fields[0] is not in the protein table, skipping\n";
      next;
    }

    $schema->resultset('ComplexComponent')->update_or_create( "complex_portal_accession" => $fields[0],
                                                              "uniprot_acc"              => $p );
  }
}

}

my %seenIpr;
my %typeMap = ( F => "Family", D => "Domain", H => "Homologous Superfamily",
A => "active site",
B => "binding site",
C => "conserved site",
P => "PTM site",
R => "Repeat");

#updated!
my $doneInterPro = 1;

if($doneInterPro != 1){
foreach my $i (@ipr){
  chomp($i);
  my @fields = split(/\t/, $i);
    

  #Now see if we have seen this interpro accession. 
  $schema->resultset('Interpro')->update_or_create( 'interpro_acc'     => $fields[0],
                                                      'ipr_type'         => $typeMap{$fields[1]},
                                                      'short_name'       => $fields[2],
                                                      'num_matches'      => $fields[3],
                                                      'child_interpro_acc' => $fields[4] eq 'None' ? undef : $fields[4],
                                                      'checked'          => $fields[5] =~ /Y/i ? 1 : 0);
  $seenIpr{$fields[0]}++;

}

foreach my $m (@iprMatches){
  next if($m =~ /^ENTRY_AC/);
  $m =~ s/\r//g;
  chomp($m);
  my @fields = split(/\t/, $m);
  if(!defined($seen{$fields[1]})){
    warn "$fields[1] is not in the protein table, skipping match\n$m";
    next;
  }
  
  if(!defined($seenIpr{$fields[0]})){
    warn "$fields[0] is not in the InterPro table, skipping match\n$m";
    next;
  }

$schema->resultset('InterproMatch')->update_or_create('interpro_acc'  => $fields[0],
                                                        'uniprot_acc'   => $fields[1],
                                                        'start'         => 1,
                                                        'end'           => 0);
}
}

#Updated
my $donePDB=1;
if($donePDB != 1){
foreach my $s (@structures){
  chomp($s);
  next if($s =~ /^Entry/); #Remove header line.

  my @fields = split(/\t/, $s);
  if(!defined($seen{$fields[0]})){
    warn "$fields[0] is not in the protein table, skipping pdb\n$s";
    next;
  }
  
    $schema->resultset('Pdb')->find_or_create( 'uniprot_acc'     => $fields[0],
                                                 'pdb_id'          => $fields[1],
                                                 'chain'           => $fields[2]);
}
}

#Checked
foreach my $t (@transcripts){
  chomp($t);
  next if($t =~ /^Entry/); #Remove header line.

  my @fields = split(/\t/, $t);
  if(!defined($seen{$fields[0]})){
    warn "$fields[0] is not in the protein table, skipping transcript\n$t";
    next;
  }
  
  foreach my $t (split/\;/, $fields[2]){
    if($t =~ /(EENST\d+) \[(\S+)\]/){
      $schema->resultset('EnsemblTranscript')->update_or_create( 'uniprot_acc'     => $fields[0],
                                                                 'uniprot_isoform' => $2,
                                                                 'ensembl_transcript_acc' => $1 );

    }else{

      $schema->resultset('EnsemblTranscript')->update_or_create( 'uniprot_acc'     => $fields[0],
                                                                 'ensembl_transcript_acc' => $t );
    }
  }
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

