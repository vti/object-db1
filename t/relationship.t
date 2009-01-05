use Test::More tests => 3;

use ObjectDB::Relationship;

my $rel = ObjectDB::Relationship->new(
    type       => 'many to one',
    orig_class => 'Article'
);
ok($rel);

is($rel->type,       'many to one');
is($rel->orig_class, 'Article');
