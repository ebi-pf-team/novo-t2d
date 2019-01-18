use utf8;
package NovoNordiskDB::Result::Target;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

NovoNordiskDB::Result::Target

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<target>

=cut

__PACKAGE__->table("target");

=head1 ACCESSORS

=head2 uniprot_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 10

=head2 source

  data_type: 'enum'
  extra: {list => ["OT","CHEMBL","REACTOME","KEGG","CP","INTERPRO","NN_launched","NN_clinical"]}
  is_nullable: 0

=head2 disease

  data_type: 'text'
  is_nullable: 1

=head2 efo_id

  data_type: 'text'
  is_nullable: 1

=head2 target_type

  data_type: 'text'
  is_nullable: 1

=head2 proteome

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "uniprot_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 10 },
  "source",
  {
    data_type => "enum",
    extra => {
      list => [
        "OT",
        "CHEMBL",
        "REACTOME",
        "KEGG",
        "CP",
        "INTERPRO",
        "NN_launched",
        "NN_clinical",
      ],
    },
    is_nullable => 0,
  },
  "disease",
  { data_type => "text", is_nullable => 1 },
  "efo_id",
  { data_type => "text", is_nullable => 1 },
  "target_type",
  { data_type => "text", is_nullable => 1 },
  "proteome",
  { data_type => "varchar", is_nullable => 1, size => 45 },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-09-17 09:06:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:miSXnIXNS8yd7UtezrQAtg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
