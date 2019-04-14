package WriteOff::Command::event;

use WriteOff::Command;
use Try::Tiny;
use IO::Prompt;
use HTML::Entities qw/decode_entities/;

sub _find {
	my $self = shift;
	if (@_ < 1) {
		$self->help;
	}

	my $e = $self->db('Event')->find(shift);
	if (!defined $e) {
		say "Invalid event id";
		exit(1);
	}

	$e;
}

sub award {
	my $self = shift;
	my $e = $self->_find(shift);
	my $mode = WriteOff::Mode->find(shift // 'fic');
	$e->score($mode->name, decay => 0, score => 0);
}

sub calibrate {
	my $self = shift;
	my $e = $self->_find(@_);
	$e->calibrate($self->config->{work});
}

sub reset {
	my $self = shift;
	my $e = $self->_find(@_);
	$e->reset_jobs;
}

sub score {
	my $self = shift;
	my $e = $self->_find(shift);
	my $mode = WriteOff::Mode->find(shift // 'fic');
	$e->theorys->mode($mode->name)->process if $e->guessing;
	$e->score($mode->name, decay => shift // 0);
}

1;
