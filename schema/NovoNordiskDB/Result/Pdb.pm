use utf8;
package NovoNordiskDB::Result::Pdb;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

NovoNordiskDB::Result::Pdb

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<pdb>

=cut

__PACKAGE__->table("pdb");

=head1 ACCESSORS

=head2 uniprot_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 10

=head2 pdb_id

  data_type: 'varchar'
  is_nullable: 0
  size: 4

=head2 chain

  data_type: 'varchar'
  is_nullable: 0
  size: 2

=cut

__PACKAGE__->add_columns(
  "uniprot_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 10 },
  "pdb_id",
  { data_type => "varchar", is_nullable => 0, size => 4 },
  "chain",
  { data_type => "varchar", is_nullable => 0, size => 2 },
);

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-09-02 18:09:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mbDGs6NGfwBObSMZKMlKJA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->add_unique_constraint(
  constraint_name => [ qw/pdb_id chain/ ],
);
1;
