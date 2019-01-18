use utf8;
package NovoNordiskDB::Result::Interpro;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

NovoNordiskDB::Result::Interpro

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<interpro>

=cut

__PACKAGE__->table("interpro");

=head1 ACCESSORS

=head2 interpro_acc

  data_type: 'varchar'
  is_nullable: 0
  size: 9

=head2 ipr_type

  data_type: 'enum'
  extra: {list => ["Family","Domain","Repeat","conserved site","Homologous Superfamily","active site","binding site","PTM site"]}
  is_nullable: 0

=head2 short_name

  data_type: 'text'
  is_nullable: 0

=head2 num_matches

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 child_interpro_acc

  data_type: 'varchar'
  is_nullable: 1
  size: 9

=head2 checked

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "interpro_acc",
  { data_type => "varchar", is_nullable => 0, size => 9 },
  "ipr_type",
  {
    data_type => "enum",
    extra => {
      list => [
        "Family",
        "Domain",
        "Repeat",
        "conserved site",
        "Homologous Superfamily",
        "active site",
        "binding site",
        "PTM site",
      ],
    },
    is_nullable => 0,
  },
  "short_name",
  { data_type => "text", is_nullable => 0 },
  "num_matches",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "child_interpro_acc",
  { data_type => "varchar", is_nullable => 1, size => 9 },
  "checked",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</interpro_acc>

=back

=cut

__PACKAGE__->set_primary_key("interpro_acc");

=head1 RELATIONS

=head2 interpro_matches

Type: has_many

Related object: L<NovoNordiskDB::Result::InterproMatch>

=cut

__PACKAGE__->has_many(
  "interpro_matches",
  "NovoNordiskDB::Result::InterproMatch",
  { "foreign.interpro_acc" => "self.interpro_acc" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-09-17 17:53:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yBNbEby0ooMYH69BuB/DcA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
