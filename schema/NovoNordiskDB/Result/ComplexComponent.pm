use utf8;
package NovoNordiskDB::Result::ComplexComponent;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

NovoNordiskDB::Result::ComplexComponent

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<complex_component>

=cut

__PACKAGE__->table("complex_component");

=head1 ACCESSORS

=head2 complex_portal_accession

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 15

=head2 uniprot_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 10

=cut

__PACKAGE__->add_columns(
  "complex_portal_accession",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 15 },
  "uniprot_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 10 },
);

=head1 RELATIONS

=head2 complex_portal_accession

Type: belongs_to

Related object: L<NovoNordiskDB::Result::ComplexPortal>

=cut

__PACKAGE__->belongs_to(
  "complex_portal_accession",
  "NovoNordiskDB::Result::ComplexPortal",
  { complex_portal_accession => "complex_portal_accession" },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-09-02 18:09:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DajRT9petdqMmk9Woc/3rQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
