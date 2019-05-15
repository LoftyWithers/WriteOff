package WriteOff::Schema::ResultSet::Image;

use strict;
use base 'WriteOff::Schema::ResultSet';

sub difficulty { 50 }

sub metadata { Carp::croak "deprecated function metadata called" }

sub order_by_score {
   return shift->order_by({ -desc => 'public_score' });
}

sub recalc_public_stats {
   my $self = shift;

   $self->next::method;

   $self->update({
      public_score => \q{
         public_score +
            (SELECT COUNT(*)
               FROM image_story
               WHERE image_id = images.id)
      },
   });
}

1;
