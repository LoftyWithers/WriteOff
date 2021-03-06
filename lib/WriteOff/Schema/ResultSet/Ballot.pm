package WriteOff::Schema::ResultSet::Ballot;

use strict;
use base 'WriteOff::Schema::ResultSet';
use WriteOff::Award qw/:awards/;

sub filled {
   my $self = shift;

   return $self->search({ filled => 1 });
}

sub unfilled {
   return shift->search_rs({ filled => 0 });
}

sub ordered {
   return shift->order_by([
      { -asc => 'type' },
      { -asc => 'updated' },
   ]);
}

sub recalc_stats {
   my $self = shift;

   while (my $row = $self->next) {
      my $votes = $row->votes;

      $row->update({
         mean  => $votes->mean,
         stdev => $votes->stdev,
      });
   }
}

sub slates {
   my $self = shift;

   my @slates;
   for my $record ($self->all) {
      push @slates, [map { $_->entry_id } $record->votes->ordered->all];
   }

   return \@slates;
}

sub round {
   Carp::croak "Deprecated method 'round' called";
}

sub mode {
   return shift->search_rs({ mode => shift }, { join => 'round' });
}

sub fic {
   return shift->mode('fic');
}

sub pic {
   return shift->mode('pic');
}

1;
