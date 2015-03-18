use utf8;
package WriteOff::Schema::Result::User;

use strict;
use warnings;
use base "WriteOff::Schema::Result";

use WriteOff::Util;
use Digest::MD5 qw/md5_hex/;

__PACKAGE__->load_components('PassphraseColumn');

__PACKAGE__->table("users");

__PACKAGE__->add_columns(
	"id",
	{ data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
	"username",
	{ data_type => "text", is_nullable => 0 },
	"password", {
		data_type        => "text",
		is_nullable      => 0,
		passphrase       => 'rfc2307',
		passphrase_class => 'SaltedDigest',
		passphrase_args  => {
			algorithm   => 'SHA-1',
			salt_random => 20,
		},
		passphrase_check_method => 'check_password',
	},
	"email",
	{ data_type => "text", is_nullable => 1 },
	"timezone",
	{ data_type => "text", default_value => "UTC", is_nullable => 1 },
	"ip",
	{ data_type => "text", is_nullable => 1 },
	"verified",
	{ data_type => "integer", default_value => 0, is_nullable => 0 },
	"mailme",
	{ data_type => "integer", default_value => 0, is_nullable => 0 },
	"created",
	{ data_type => "timestamp", is_nullable => 1 },
	"updated",
	{ data_type => "timestamp", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("email_unique", ["email"]);

__PACKAGE__->add_unique_constraint("username_unique", ["username"]);

__PACKAGE__->has_many(
	"artists",
	"WriteOff::Schema::Result::Artist",
	{ "foreign.user_id" => "self.id" },
	{ cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
	"images",
	"WriteOff::Schema::Result::Image",
	{ "foreign.user_id" => "self.id" },
	{ cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
	"news",
	"WriteOff::Schema::Result::News",
	{ "foreign.user_id" => "self.id" },
	{ cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
	"prompts",
	"WriteOff::Schema::Result::Prompt",
	{ "foreign.user_id" => "self.id" },
	{ cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
	"storys",
	"WriteOff::Schema::Result::Story",
	{ "foreign.user_id" => "self.id" },
	{ cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
	"tokens",
	"WriteOff::Schema::Result::Token",
	{ "foreign.user_id" => "self.id" },
	{ cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
	"user_events",
	"WriteOff::Schema::Result::UserEvent",
	{ "foreign.user_id" => "self.id" },
	{ cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
	"user_roles",
	"WriteOff::Schema::Result::UserRole",
	{ "foreign.user_id" => "self.id" },
	{ cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
	"vote_records",
	"WriteOff::Schema::Result::VoteRecord",
	{ "foreign.user_id" => "self.id" },
	{ cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many("roles", "user_roles", "role");

__PACKAGE__->mk_group_accessors(
	column => 'role',
	column => 'prompt_skill',
	column => 'hugbox_score',
);

sub name {
	return shift->username;
}

sub username_and_email {
	my $self = shift;

	return sprintf "%s <%s>", $self->username, $self->email;
}

sub last_author {
	my $self = shift;
	my $last_story = $self->storys->order_by({ -desc => 'updated' })->first;
	return $last_story ? $last_story->artist->name : undef;
}

sub last_artist {
	my $self = shift;
	my $last_image = $self->images->order_by({ -desc => 'updated' })->first;
	return $last_image ? $last_image->artist->name : undef;
}

sub primary_artist {
	my $self = shift;
	my $artists = $self->result_source->schema->resultset('Artist');

	my %freq;
	$freq{$_->artist_id}++ for $self->storys, $self->images;

	if (!%freq) {
		# No artist, make one
		my $artist = $artists->find_or_new({ name => $self->username });

		# Shouldn't need to do this -- create artist when user is created
		if (!$artist->in_storage) {
			$artist->user_id($self->id);
			$artist->score(0);
			$artist->insert;
		}

		return $artist;
	}
	else {
		my $max = [0, 0];
		while (my ($aid, $count) = each %freq) {
			$max = [$aid, $count] if $count > $max->[1];
		}
		return $artists->find($max->[0]);
	}
}

sub is_admin {
	my $self = shift;

	return $self->roles->search({ role => 'admin' })->count;
}

sub find_token {
	my ($self, $type, $value) = @_;

	return $self->tokens->search({
		type => $type,
		value => $value,
		expires => { '>' => DateTime->now },
	})->single;
}

sub new_token {
	my ($self, $type, $address) = @_;
	my %token = (
		address => $address,
		expires => DateTime->now->add(days => 1),
		value   => WriteOff::Util::token(),
	);

	if (my $row = $self->tokens->find($self->id, $type)) {
		$row->update(\%token);
		return $row;
	}
	else {
		$token{type} = $type;
		return $self->create_related('tokens', \%token);
	}
}

sub new_password {
	my $self = shift;

	my $pass = join q{}, map { ('a'..'z')[rand 26] } 0..4;

	$self->update({ password => $pass });

	return $pass;
}

sub offset {
	(hex substr md5_hex(shift->id), 0, 8) / (1 << 32);
}

1;
