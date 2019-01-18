use utf8;
package NovoNordiskDB::Result::InterproMatch;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

NovoNordiskDB::Result::InterproMatch

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<interpro_match>

=cut

__PACKAGE__->table("interpro_match");

=head1 ACCESSORS

=head2 interpro_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 9

=head2 uniprot_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 10

=head2 start

  data_type: 'integer'
  is_nullable: 0

=head2 end

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "interpro_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 9 },
  "uniprot_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 10 },
  "start",
  { data_type => "integer", is_nullable => 0 },
  "end",
  { data_type => "integer", is_nullable => 0 },
);

=head1 RELATIONS

=head2 interpro_acc

Type: belongs_to

Related object: L<NovoNordiskDB::Result::Interpro>

=cut

__PACKAGE__->belongs_to(
  "interpro_acc",
  "NovoNordiskDB::Result::Interpro",
  { interpro_acc => "interpro_acc" },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yDVLmjvJiXvfgMRm6+baMg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
