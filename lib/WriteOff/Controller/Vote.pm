package WriteOff::Controller::Vote;
use Moose;
use namespace::autoclean;
use Scalar::Util qw/looks_like_number/;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

WriteOff::Controller::Vote - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub cast :Private {
	my ($self, $c) = @_;

	my $rounds = $c->stash->{event}->rounds->search({
		mode => $c->stash->{mode},
		action => 'vote',
	});

	my $round = $c->stash->{round} = $rounds->active->first;

	if ($round && $round->name eq 'final' && $round->event->judges->count) {
		if (!$c->user->judges($round->event)) {
			$c->stash->{notJudge} = 1;
		}
	}

	if ($round && $round->entrys->count && $c->user && !$c->stash->{notJudge}) {
		my $ballot = $c->stash->{event}->ballots->find_or_create({
			user_id => $c->user->id,
			round_id => $round->id,
		});

		$c->stash->{pool} = $round->entrys->search({
			'me.id' => { -not_in => $ballot->votes->get_column('entry_id')->as_query },
			user_id => { '!=' => $c->user->id },
		});

		if (!$ballot->votes->count) {
			# Copy previous votes to the ballot
			my $prevRound = $rounds->before($round)->first;
			my $prevBallot = $prevRound && $prevRound->ballots->search({ user_id => $c->user->id })->first;

			if ($prevBallot) {
				for my $vote ($prevBallot->votes->join('entry')->all) {
					next if $vote->entry->round_id != $round->id;
					next if $ballot->search_related('votes', { entry_id => $vote->entry_id })->count;

					$ballot->create_related('votes', {
						entry_id => $vote->entry_id,
						value => $vote->value,
					});
				}
			}

			# Assign some stories to the ballot
			my $mins = $round->end->delta_ms($round->start)->in_units('minutes');
			my $w = $mins / 1440 * $c->config->{work}{threshold} * $c->config->{work}{voter};

			for my $entry ($c->stash->{pool}->sample->all) {
				$entry->create_related('votes', { ballot_id => $ballot->id });
				$w -= $entry->work($c->config->{work});
				last if $w < 0;
			}
		}

		$c->stash->{ballot} = $ballot;
		$c->stash->{ordered} = $ballot->votes->ordered;
		$c->stash->{unordered} = $ballot->votes->search({ value => undef, abstained => 0 });
		$c->stash->{abstained} = $ballot->votes->search({ abstained => 1 });
	}

	if ($round) {
		$c->stash->{countdown} = $round->end;
		push @{ $c->stash->{title} }, $c->stash->{label} = $c->string($round->name);
	}
	else {
		if ($rounds->upcoming->count) {
			$c->stash->{countdown} = $rounds->upcoming->ordered->first->start;
		}
	}

	if ($c->user) {
		$c->stash->{ballots} = $c->stash->{event}->ballots->search({
			user_id => $c->user->id,
			mode => $c->stash->{mode},
			$c->stash->{round} ? (round_id => { '!=' => $c->stash->{round}->id }) : (),
		}, {
			join => 'votes',
			prefetch => 'round',
			group_by => 'me.id',
			having => \'COUNT(votes.value) > 1',
		});
	}

	push @{ $c->stash->{title} }, $c->string('vote');
	$c->stash->{template} = 'vote/cast.tt';

	$c->forward('do_cast') if $c->req->method eq 'POST';
}

sub do_cast :Private {
	my ($self, $c) = @_;

	my $ballot = $c->stash->{ballot} or return;

	my $action = $c->req->params->{action} // 'reorder';
	if ($action eq 'abstain' || $action eq 'unabstain') {
		my $id = $c->req->params->{vote};
		return unless looks_like_number $id;

		my $vote = $ballot->votes->find($id);
		$c->detach('/error', [ 'Vote not found' ]) unless $vote;

		if ($action eq 'abstain') {
			return if $ballot->abstains <= 0;
			$vote->update({ abstained => 1, value => undef });
			$c->res->body($ballot->abstains);
		}
		elsif ($action eq 'unabstain') {
			$vote->update({ abstained => 0 });
			$c->res->body($ballot->abstains);
		}
	}
	elsif ($action eq 'append') {
		$c->detach('/error', [ 'You have candidates remaining' ]) if $c->stash->{unordered}->count;

		if (!$c->stash->{pool}->count) {
			$c->res->body('None left');
		}
		else {
			my $tail = $c->stash->{pool}->sample->first;
			$c->stash->{vote} = $tail->create_related('votes', { ballot_id => $ballot->id });
			$c->stash->{score} = 'N/A';
			$c->stash->{template} = 'vote/ballot-item.tt';
		}
	}
	elsif ($action eq 'reorder') {
		my $votes = $ballot->votes;
		my %okay = map { $_->id => 1 } $votes->search({ abstained => 0 });
		my @order = grep { defined && $okay{$_} } $c->req->param("order"), $c->req->param("order[]");

		$votes->update({ value => undef });
		while (@order) {
			$votes->find(shift @order)->update({ value => scalar @order });
		}
	}
}

sub pic :PathPart('vote') :Chained('/event/pic') :Args(0) {
	my ($self, $c) = @_;

	$c->stash->{mode} = 'pic';
	$c->stash->{view} = $c->controller('Art')->action_for('view');

	$c->forward('cast');
}

sub fic :PathPart('vote') :Chained('/event/fic') :Args(0) {
	my ($self, $c) = @_;

	$c->stash->{mode} = 'fic';
	$c->stash->{view} = $c->controller('Fic')->action_for('view');

	$c->forward('cast');
}

=head1 AUTHOR

Cameron Thornton E<lt>cthor@cpan.orgE<gt>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
