package ObjectDB::SQL::Rollback;

use strict;
use warnings;

use base 'ObjectDB::SQL';

sub to_string {
    my $self = shift;

    my $query = "";

    $query .= 'ROLLBACK';

    return $query;
}

1;
