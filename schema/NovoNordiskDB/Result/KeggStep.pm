use utf8;
package NovoNordiskDB::Result::KeggStep;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

NovoNordiskDB::Result::KeggStep

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<kegg_step>

=cut

__PACKAGE__->table("kegg_step");

=head1 ACCESSORS

=head2 kegg_pathway_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 20

=head2 uniprot_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 10

=head2 kegg_protein

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 kegg_gene

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 kegg_protein_desc

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "kegg_pathway_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 20 },
  "uniprot_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 10 },
  "kegg_protein",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "kegg_gene",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "kegg_protein_desc",
  { data_type => "varchar", is_nullable => 1, size => 45 },
);

=head1 RELATIONS

=head2 kegg_pathway

Type: belongs_to

Related object: L<NovoNordiskDB::Result::Kegg>

=cut

__PACKAGE__->belongs_to(
  "kegg_pathway",
  "NovoNordiskDB::Result::Kegg",
  { kegg_pathway_id => "kegg_pathway_id" },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6J2haIcoRbuno9Jk5jc5GA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
