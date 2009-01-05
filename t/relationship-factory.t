use Test::More tests => 2;

use ObjectDB::RelationshipFactory;

my $rel = ObjectDB::RelationshipFactory->build(type => 'many to one');
ok($rel);

is(ref $rel, 'ObjectDB::Relationship::ManyToOne');
