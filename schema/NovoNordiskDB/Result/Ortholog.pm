use utf8;
package NovoNordiskDB::Result::Ortholog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

NovoNordiskDB::Result::Ortholog

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ortholog>

=cut

__PACKAGE__->table("ortholog");

=head1 ACCESSORS

=head2 uniprot_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 10

=head2 ortholog_uniprot_acc

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 species

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "uniprot_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 10 },
  "ortholog_uniprot_acc",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "species",
  { data_type => "integer", is_nullable => 0 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<otholog_accs>

=over 4

=item * L</uniprot_acc>

=item * L</ortholog_uniprot_acc>

=back

=cut

__PACKAGE__->add_unique_constraint("otholog_accs", ["uniprot_acc", "ortholog_uniprot_acc"]);

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-09-17 13:46:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uaeHrpoxvH1ywk3Vdq/2jQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
