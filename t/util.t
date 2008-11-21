use Test::More tests => 1;

use lib 't/lib';

use User;

my $u = User->new(name => 'bar');

is_deeply($u->to_hash, {id => undef, name => 'bar', password => undef});
