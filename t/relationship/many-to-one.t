use Test::More tests => 3;

use ObjectDB::Relationship::ManyToOne;

use lib 't/lib';

my $rel = ObjectDB::Relationship::ManyToOne->new(
    type       => 'many to one',
    class      => 'User',
    orig_class => 'Article',
    map        => {user_id => 'id'}
);
ok($rel);

is($rel->related_table, 'user');

is_deeply(
    $rel->to_source,
    {   name       => 'user',
        join       => 'left',
        constraint => {'user.id' => 'article.user_id'}
    }
);

