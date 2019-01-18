use utf8;
package NovoNordiskDB::Result::EnsemblTranscript;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

NovoNordiskDB::Result::EnsemblTranscript

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ensembl_transcript>

=cut

__PACKAGE__->table("ensembl_transcript");

=head1 ACCESSORS

=head2 uniprot_acc

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 10

=head2 uniprot_isofrom

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 ensembl_transcript_acc

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "uniprot_acc",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 10 },
  "uniprot_isofrom",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "ensembl_transcript_acc",
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-09-02 18:09:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ut6ff4yhu98nRoRyZAxfcQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
