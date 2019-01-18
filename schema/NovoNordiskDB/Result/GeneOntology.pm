use utf8;
package NovoNordiskDB::Result::GeneOntology;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

NovoNordiskDB::Result::GeneOntology

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<gene_ontology>

=cut

__PACKAGE__->table("gene_ontology");

=head1 ACCESSORS

=head2 uniprot_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 10

=head2 go_id

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 go_class

  data_type: 'enum'
  extra: {list => ["CC","BP","MF"]}
  is_nullable: 0

=head2 go_name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "uniprot_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 10 },
  "go_id",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "go_class",
  {
    data_type => "enum",
    extra => { list => ["CC", "BP", "MF"] },
    is_nullable => 0,
  },
  "go_name",
  { data_type => "text", is_nullable => 0 },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OLVsB2prNiom1TtEjr6xhQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
