package DB;

use strict;
use warnings;

use base 'ObjectDB';

our $dbh;

sub init_db {
    my $self = shift;

    return $dbh if $dbh;

    $dbh = DBI->connect('dbi:SQLite:table.db');
    $dbh->do("PRAGMA default_synchronous = OFF");
    $dbh->do("PRAGMA temp_store = MEMORY");

    die $DBI::errorstr unless $dbh;
}

1;
