use utf8;
package NovoNordiskDB::Result::ComplexPortal;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

NovoNordiskDB::Result::ComplexPortal

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<complex_portal>

=cut

__PACKAGE__->table("complex_portal");

=head1 ACCESSORS

=head2 complex_portal_accession

  data_type: 'varchar'
  is_nullable: 0
  size: 15

=head2 description

  data_type: 'text'
  is_nullable: 0

=head2 number_proteins

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "complex_portal_accession",
  { data_type => "varchar", is_nullable => 0, size => 15 },
  "description",
  { data_type => "text", is_nullable => 0 },
  "number_proteins",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</complex_portal_accession>

=back

=cut

__PACKAGE__->set_primary_key("complex_portal_accession");

=head1 RELATIONS

=head2 complex_components

Type: has_many

Related object: L<NovoNordiskDB::Result::ComplexComponent>

=cut

__PACKAGE__->has_many(
  "complex_components",
  "NovoNordiskDB::Result::ComplexComponent",
  {
    "foreign.complex_portal_accession" => "self.complex_portal_accession",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-09-02 18:09:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1utNGTjmo6Z8ODzvGG6vBw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
