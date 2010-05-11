use Test::More tests => 8;

use lib 't/lib';

use Author;

my $author = Author->new;


### use columns method as a getter
ok($author);
is_deeply([$author->columns], []);


### set one column
$author->column(id => 'boo');
is_deeply([$author->columns], [qw/ id /]);


### TO DO: test default value


### use columns method as a setter and pass multiple values
my $author = $author->columns( id => 'bar', name => 'test1' );
ok ( ref $author eq 'Author' );
ok ( $author->column('id') eq 'bar' && $author->column('name') eq 'test1' );


### set values to undef
$author->columns( id => undef, name => undef );
ok ( !defined $author->column('id') && !defined $author->column('name') );


### check getter after multiple values have been set
$author = Author->new;
$author->columns( id => 'bar', name => 'test1' );
is_deeply([$author->columns], [qw/ id name /]);


### od number of hash elements
ok ( !eval{ $author->columns( id =>'bar','odd number of hash elements') } );
