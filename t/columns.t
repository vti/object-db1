use Test::More tests => 3;

use lib 't/lib';

use User;

my $u = User->new;

ok($u);
is_deeply([$u->columns], []);

$u->column(id => 'boo');
is_deeply([$u->columns], [qw/ id /]);
