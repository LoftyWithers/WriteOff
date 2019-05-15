use utf8;
package WriteOff::Schema::Result::UserEvent;

use strict;
use warnings;
use base "WriteOff::Schema::Result";

__PACKAGE__->table("user_event");

__PACKAGE__->add_columns(
   "user_id",
   { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
   "event_id",
   { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
   "role",
   { data_type => "text", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("user_id", "event_id", "role");

__PACKAGE__->belongs_to("event", "WriteOff::Schema::Result::Event", "event_id");
__PACKAGE__->belongs_to("user", "WriteOff::Schema::Result::User", "user_id");

1;
