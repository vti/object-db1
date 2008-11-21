package ObjectDB::Base;

use strict;
use warnings;

sub new {
    my $class = shift;

    return bless
      exists $_[0] ? exists $_[1] ? {@_} : $_[0] : {},
      ref $class || $class;
}

1;
