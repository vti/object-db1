package DB;

use strict;
use warnings;

use base 'ObjectDB';

our $dbh;

sub init_db {
    my $self = shift;

    return $dbh if $dbh;

    $dbh = DBI->connect('dbi:SQLite:table.db');

    die $DBI::errorstr unless $dbh;

    #die $dbh->{Driver}->{Name};
}

1;
