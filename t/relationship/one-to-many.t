use Test::More tests => 3;

use ObjectDB::Relationship::OneToMany;

use lib 't/lib';

my $rel = ObjectDB::Relationship::OneToMany->new(
    name       => 'articles',
    type       => 'one to many',
    orig_class => 'Author',
    class      => 'Article',
    where      => [type => 'article'],
    map        => {id => 'author_id'}
);
ok($rel);

is($rel->related_table, 'article');

is_deeply(
    $rel->to_source,
    {   name       => 'article',
        as         => 'article',
        join       => 'left',
        constraint => ['article.author_id' => 'author.id', 'article.type' => 'article']
    }
);

