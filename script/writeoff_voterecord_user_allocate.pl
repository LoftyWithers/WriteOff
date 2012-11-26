#!/usr/bin/env perl

# Tries and finds the user associated with old data
use 5.014;
use FindBin '$Bin';
use lib "$Bin/../lib";
use WriteOff::Schema;

my $schema = WriteOff::Schema->connect("dbi:SQLite:$Bin/../WriteOff.db");

for my $record ( $schema->resultset('VoteRecord')->search({ user_id => undef }) )
{
	next unless $record->ip;
	if( my $user = $schema->resultset('User')->search({ ip => $record->ip })->first )
	{
		$record->update({ user_id => $user->id });
		printf "%03d - %s - %s\n", $record->id, $record->event->prompt, $user->username;
	}
}