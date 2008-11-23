package UserAdmin;

use base 'DB';

__PACKAGE__->meta(
    table => 'user_admin',
    columns => [qw/ user_id beard /],
    primary_keys => ['user_id'],
);

1;
