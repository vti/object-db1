package Admin;

use strict;
use warnings;

use base 'User';

__PACKAGE__->meta->add_relationship('user_admin' =>
      {type => 'one to one', class => 'UserAdmin', map => {id => 'user_id'}});

1;
