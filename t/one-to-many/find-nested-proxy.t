#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 35;

use lib 't/lib';

use Author;
use Podcast;
use Category;


# Create an author with article and comments on article
my $author = Author->new(
    name     => 'foo',
    articles => {title => 'article title', comments => [{content => 'comment content'}], category_id=>1 }
)->create;


# First simple test
my $authors = Author->find(with => [qw/articles articles.comments/]);
is( @$authors, 1);
is( $authors->[0]->related('articles')->[0]->column('title'), 'article title');
is( $authors->[0]
        ->related('articles')->[0]
        ->related('comments')->[0]->column('content'), 'comment content' );


# Save data for validation purposes
my $article_id;
my $comment_master_id;
my $comment_id;

ok ( $article_id = $authors->[0]->related('articles')->[0]->column('id') );
ok ( $comment_master_id = $authors->[0]
                            ->related('articles')->[0]
                            ->related('comments')->[0]
                            ->column('master_id') );
ok ( $comment_id = $authors->[0]
                            ->related('articles')->[0]
                            ->related('comments')->[0]
                            ->column('id') );


# Autoload articles if only articles.comments is requested
$authors = Author->find(with => [qw/articles.comments/]);
is( @$authors, 1 );
ok( !defined $authors->[0]->related('articles')->[0]->column('title') );
is( $authors->[0]->related('articles')->[0]->column('id'), $article_id );
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
        ->column('content'), 'comment content' );


# Autoload articles if only articles.comments is requested, don't load
# articles a second time
$authors = Author->find(with => [qw/articles.comments articles/]);
is( @$authors, 1 );
ok( !defined $authors->[0]->related('articles')->[0]->column('title') );
is( $authors->[0]->related('articles')->[0]->column('id'), $article_id );
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
        ->column('content'), 'comment content' );


# Add another level to up the ante
Podcast->new( id=>$comment_master_id, title=>'pod title' )->create;


# Find all authors with all articles with all comments with podcast
$authors = Author->find(with => [qw/articles articles.comments articles.comments.podcast/]);
is( @$authors, 1);
is( $authors->[0]->related('articles')->[0]->column('title'), 'article title' );
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
        ->column('content'), 'comment content' );
is( $authors->[0]
        ->related('articles')->[0]
        ->related('comments')->[0]
        ->related('podcast')->column('title'), 'pod title' );


# Find all authors with comment related podcasts (and primary key data of articles an comments)
$authors = Author->find(with => [qw/articles.comments.podcast/]);
is( @$authors, 1);
ok( !defined $authors->[0]->related('articles')->[0]->column('title') );
is( $authors->[0]->related('articles')->[0]->column('id'), $article_id );
ok( !defined $authors->[0]->related('articles')->[0]->related('comments')->[0]
        ->column('content') );
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
        ->column('id'), $comment_id );
is( $authors->[0]
        ->related('articles')->[0]
        ->related('comments')->[0]
        ->related('podcast')->column('title'), 'pod title' );


# Find articles, than comments, than category
Category->new( id=>1, title=>"stuff")->create;
$authors = Author->find(with => [qw/articles articles.comments articles.category/]);
is(@$authors, 1);
is($authors->[0]->related('articles')->[0]->column('title'), 'article title');
is($authors->[0]->related('articles')->[0]->related('comments')->[0]->column('content'), 'comment content');
is($authors->[0]->related('articles')->[0]->related('category')->column('title'), 'stuff');


# Find comments, than category
Category->new( id=>1, title=>"stuff")->create;
$authors = Author->find(with => [qw/articles.comments articles.category/]);
is(@$authors, 1);
is($authors->[0]->related('articles')->[0]->column('id'), $article_id);
is($authors->[0]->related('articles')->[0]->related('comments')->[0]->column('content'), 'comment content');
is($authors->[0]->related('articles')->[0]->related('category')->column('title'), 'stuff');



$authors = Author->find(
    where => ['articles.comments.type' => 'article'],
    with  => [qw/articles articles.comments/]
);

is(@$authors, 1);
is($authors->[0]->related('articles')->[0]->column('title'), 'article title');
is( $authors->[0]->related('articles')->[0]->related('comments')->[0]
      ->column('content'),
    'comment content'
);

$author->delete;


