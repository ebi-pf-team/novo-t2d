use utf8;
package NovoNordiskDB::Result::ReactomeStep;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

NovoNordiskDB::Result::ReactomeStep

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<reactome_step>

=cut

__PACKAGE__->table("reactome_step");

=head1 ACCESSORS

=head2 pathway_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 20

=head2 uniprot_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 10

=head2 reaction_id

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 reaction_description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pathway_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 20 },
  "uniprot_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 10 },
  "reaction_id",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "reaction_description",
  { data_type => "text", is_nullable => 1 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<unique_id_acc>

=over 4

=item * L</pathway_id>

=item * L</uniprot_acc>

=back

=cut

__PACKAGE__->add_unique_constraint("unique_id_acc", ["pathway_id", "uniprot_acc"]);

=head1 RELATIONS

=head2 pathway

Type: belongs_to

Related object: L<NovoNordiskDB::Result::Reactome>

=cut

__PACKAGE__->belongs_to(
  "pathway",
  "NovoNordiskDB::Result::Reactome",
  { pathway_id => "pathway_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 uniprot_acc

Type: belongs_to

Related object: L<NovoNordiskDB::Result::Protein>

=cut

__PACKAGE__->belongs_to(
  "uniprot_acc",
  "NovoNordiskDB::Result::Protein",
  { uniprot_acc => "uniprot_acc" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-09-17 17:53:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qYneGKuWeRhm2Cd4LHDiqw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
