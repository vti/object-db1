use Test::More tests => 2;

use ObjectDB::Relationship;

my $rel = ObjectDB::Relationship->build(name => 'foo', type => 'many to one');
ok($rel);

is(ref $rel, 'ObjectDB::Relationship::ManyToOne');
