use utf8;
package NovoNordiskDB::Result::Protein;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

NovoNordiskDB::Result::Protein

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<protein>

=cut

__PACKAGE__->table("protein");

=head1 ACCESSORS

=head2 uniprot_acc

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 uniprot_id

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 reviewed

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 gene_name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 0

=head2 species

  data_type: 'text'
  is_nullable: 0

=head2 ensembl_gene

  data_type: 'text'
  is_nullable: 1

=head2 complex_portal_xref

  data_type: 'text'
  is_nullable: 1

=head2 reactome_xref

  data_type: 'text'
  is_nullable: 1

=head2 kegg_xref

  data_type: 'text'
  is_nullable: 1

=head2 secreted

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 proteome

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "uniprot_acc",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "uniprot_id",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "reviewed",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "gene_name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 0 },
  "species",
  { data_type => "text", is_nullable => 0 },
  "ensembl_gene",
  { data_type => "text", is_nullable => 1 },
  "complex_portal_xref",
  { data_type => "text", is_nullable => 1 },
  "reactome_xref",
  { data_type => "text", is_nullable => 1 },
  "kegg_xref",
  { data_type => "text", is_nullable => 1 },
  "secreted",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "proteome",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</uniprot_acc>

=back

=cut

__PACKAGE__->set_primary_key("uniprot_acc");

=head1 UNIQUE CONSTRAINTS

=head2 C<uniprot_id_UNIQUE>

=over 4

=item * L</uniprot_id>

=back

=cut

__PACKAGE__->add_unique_constraint("uniprot_id_UNIQUE", ["uniprot_id"]);

=head1 RELATIONS

=head2 complex_components

Type: has_many

Related object: L<NovoNordiskDB::Result::ComplexComponent>

=cut

__PACKAGE__->has_many(
  "complex_components",
  "NovoNordiskDB::Result::ComplexComponent",
  { "foreign.uniprot_acc" => "self.uniprot_acc" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ensembl_transcripts

Type: has_many

Related object: L<NovoNordiskDB::Result::EnsemblTranscript>

=cut

__PACKAGE__->has_many(
  "ensembl_transcripts",
  "NovoNordiskDB::Result::EnsemblTranscript",
  { "foreign.uniprot_acc" => "self.uniprot_acc" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gene_ontologies

Type: has_many

Related object: L<NovoNordiskDB::Result::GeneOntology>

=cut

__PACKAGE__->has_many(
  "gene_ontologies",
  "NovoNordiskDB::Result::GeneOntology",
  { "foreign.uniprot_acc" => "self.uniprot_acc" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 interpro_matches

Type: has_many

Related object: L<NovoNordiskDB::Result::InterproMatch>

=cut

__PACKAGE__->has_many(
  "interpro_matches",
  "NovoNordiskDB::Result::InterproMatch",
  { "foreign.uniprot_acc" => "self.uniprot_acc" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kegg_steps

Type: has_many

Related object: L<NovoNordiskDB::Result::KeggStep>

=cut

__PACKAGE__->has_many(
  "kegg_steps",
  "NovoNordiskDB::Result::KeggStep",
  { "foreign.uniprot_acc" => "self.uniprot_acc" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 orthologs

Type: has_many

Related object: L<NovoNordiskDB::Result::Ortholog>

=cut

__PACKAGE__->has_many(
  "orthologs",
  "NovoNordiskDB::Result::Ortholog",
  { "foreign.uniprot_acc" => "self.uniprot_acc" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pdbs

Type: has_many

Related object: L<NovoNordiskDB::Result::Pdb>

=cut

__PACKAGE__->has_many(
  "pdbs",
  "NovoNordiskDB::Result::Pdb",
  { "foreign.uniprot_acc" => "self.uniprot_acc" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 reactome_steps

Type: has_many

Related object: L<NovoNordiskDB::Result::ReactomeStep>

=cut

__PACKAGE__->has_many(
  "reactome_steps",
  "NovoNordiskDB::Result::ReactomeStep",
  { "foreign.uniprot_acc" => "self.uniprot_acc" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 targets

Type: has_many

Related object: L<NovoNordiskDB::Result::Target>

=cut

__PACKAGE__->has_many(
  "targets",
  "NovoNordiskDB::Result::Target",
  { "foreign.uniprot_acc" => "self.uniprot_acc" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-09-17 17:53:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LOG6j/sy3czlnah76qgR1A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
