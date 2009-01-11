package ObjectDB::SQL::Commit;

use strict;
use warnings;

use base 'ObjectDB::SQL';

sub to_string {
    my $self = shift;

    my $query = "";

    $query .= 'COMMIT';

    return $query;
}

1;
