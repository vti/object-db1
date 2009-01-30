use Test::More tests => 3;

use ObjectDB::Relationship::OneToOne;

use lib 't/lib';

my $rel = ObjectDB::Relationship::OneToOne->new(
    type       => 'one to one',
    orig_class => 'User',
    class      => 'Article',
    map        => {id => 'user_id'}
);
ok($rel);

is($rel->related_table, 'article');

is_deeply(
    $rel->to_source,
    {   name       => 'article',
        join       => 'left',
        constraint => ['article.user_id' => 'user.id']
    }
);

