use utf8;
package NovoNordiskDB::Result::Kegg;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

NovoNordiskDB::Result::Kegg

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<kegg>

=cut

__PACKAGE__->table("kegg");

=head1 ACCESSORS

=head2 kegg_pathway_id

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 description

  data_type: 'text'
  is_nullable: 0

=head2 number_steps

  data_type: 'integer'
  is_nullable: 0

=head2 kegg_disease

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "kegg_pathway_id",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "description",
  { data_type => "text", is_nullable => 0 },
  "number_steps",
  { data_type => "integer", is_nullable => 0 },
  "kegg_disease",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</kegg_pathway_id>

=back

=cut

__PACKAGE__->set_primary_key("kegg_pathway_id");

=head1 RELATIONS

=head2 kegg_steps

Type: has_many

Related object: L<NovoNordiskDB::Result::KeggStep>

=cut

__PACKAGE__->has_many(
  "kegg_steps",
  "NovoNordiskDB::Result::KeggStep",
  { "foreign.kegg_pathway_id" => "self.kegg_pathway_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-09-02 18:09:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ro1CH4/puAx2qeT2471A9g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
