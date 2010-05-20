#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 14;

use lib 't/lib';

use Author;
use Podcast;

my $author = Author->new(
    name     => 'foo',
    articles => {title => 'foo', comments => [{content => 'bar'}]}
);

$author->create;

my $authors = Author->find(with => [qw/articles articles.comments/]);

is(@$authors, 1);
is($authors->[0]->related('articles')->[0]->column('title'), 'foo');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'bar'
);
my $article_id = $authors->[0]->related('articles')->[0]->column('id');
my $comment_id = $authors->[0]->related('articles')->[0]->related('comments')->[0]->column('id');


# Autoload articles if only articles.comments is requested
$authors = Author->find(with => [qw/articles.comments/]);
is(@$authors, 1);
ok( !defined $authors->[0]->related('articles')->[0]->column('title') );
is( $authors->[0]->related('articles')->[0]->column('id'), $article_id );
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'bar'
);


# Autoload articles if only articles.comments is requested, don't load
# articles a second time
$authors = Author->find(with => [qw/articles.comments articles/]);
is(@$authors, 1);
ok( !defined $authors->[0]->related('articles')->[0]->column('title') );
is( $authors->[0]->related('articles')->[0]->column('id'), $article_id );
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'bar'
);

#$authors = Author->find(with => [qw/articles articles.comments articles.comments.podcast/]);

# add another level
#Podcast->new( id=>$comment_id, title=>'add level' )->create;
#warn "still works";
#$authors = Author->find(with => [qw/articles.comments.podcast/]);
#is(@$authors, 1);
#ok( !defined $authors->[0]->related('articles')->[0]->column('title') );
#is( $authors->[0]->related('articles')->[0]->column('id'), $article_id );
#is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
#      ->column('content'),
#    'bar'
#);


$authors = Author->find(
    where => ['articles.comments.type' => 'article'],
    with  => [qw/articles articles.comments/]
);

is(@$authors, 1);
is($authors->[0]->related('articles')->[0]->column('title'), 'foo');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'bar'
);

$author->delete;


