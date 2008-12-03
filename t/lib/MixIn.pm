package MixIn;

use strict;
use warnings;

use base 'ObjectDB::MixIn';

sub hello {
    '123';
}

sub hello2 {
}

sub _hello {
}

1;
