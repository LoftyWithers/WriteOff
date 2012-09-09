use utf8;
package WriteOff::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

WriteOff::Schema::Result::User

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=item * L<DBIx::Class::InflateColumn::Serializer>

=back

=cut

__PACKAGE__->load_components(
  "InflateColumn::DateTime",
  "TimeStamp",
  "PassphraseColumn",
  "InflateColumn::Serializer",
);

=head1 TABLE: C<users>

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'text'
  is_nullable: 1

=head2 password

  data_type: 'text'
  is_nullable: 1

=head2 email

  data_type: 'text'
  is_nullable: 1

=head2 timezone

  data_type: 'text'
  default_value: 'UTC'
  is_nullable: 1

=head2 ip

  data_type: 'text'
  is_nullable: 1

=head2 verified

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 mailme

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 token

  data_type: 'text'
  is_nullable: 1

=head2 created

  data_type: 'timestamp'
  is_nullable: 1

=head2 active

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "text", is_nullable => 1 },
  "password",
  { data_type => "text", is_nullable => 1 },
  "email",
  { data_type => "text", is_nullable => 1 },
  "timezone",
  { data_type => "text", default_value => "UTC", is_nullable => 1 },
  "ip",
  { data_type => "text", is_nullable => 1 },
  "verified",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "mailme",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "token",
  { data_type => "text", is_nullable => 1 },
  "created",
  { data_type => "timestamp", is_nullable => 1 },
  "active",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<email_unique>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("email_unique", ["email"]);

=head2 C<username_unique>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("username_unique", ["username"]);

=head1 RELATIONS

=head2 images

Type: has_many

Related object: L<WriteOff::Schema::Result::Image>

=cut

__PACKAGE__->has_many(
  "images",
  "WriteOff::Schema::Result::Image",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 prompts

Type: has_many

Related object: L<WriteOff::Schema::Result::Prompt>

=cut

__PACKAGE__->has_many(
  "prompts",
  "WriteOff::Schema::Result::Prompt",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 storys

Type: has_many

Related object: L<WriteOff::Schema::Result::Story>

=cut

__PACKAGE__->has_many(
  "storys",
  "WriteOff::Schema::Result::Story",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_events

Type: has_many

Related object: L<WriteOff::Schema::Result::UserEvent>

=cut

__PACKAGE__->has_many(
  "user_events",
  "WriteOff::Schema::Result::UserEvent",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_roles

Type: has_many

Related object: L<WriteOff::Schema::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "WriteOff::Schema::Result::UserRole",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vote_records

Type: has_many

Related object: L<WriteOff::Schema::Result::VoteRecord>

=cut

__PACKAGE__->has_many(
  "vote_records",
  "WriteOff::Schema::Result::VoteRecord",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 events

Type: many_to_many

Composing rels: L</user_events> -> event

=cut

__PACKAGE__->many_to_many("events", "user_events", "event");

=head2 roles

Type: many_to_many

Composing rels: L</user_roles> -> role

=cut

__PACKAGE__->many_to_many("roles", "user_roles", "role");


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-09-09 00:30:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0L3vwi0WOIhQaWyYq3rwvA

__PACKAGE__->add_columns(
	password => {
		passphrase       => 'rfc2307',
		passphrase_class => 'SaltedDigest',
		passphrase_args  => {
			algorithm   => 'SHA-1',
			salt_random => 20,
		},
		passphrase_check_method => 'check_password',
	},
	created => {data_type => 'timestamp', set_on_create => 1},
);


sub new_token {
	my $row = shift;
	
	my $token = Digest->new('MD5')
		->add( join("", time, $row->password, rand(10000), $$) )
		->hexdigest;
		
	$row->update({ token => $token });
	
	return $token;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
