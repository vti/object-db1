package ObjectDB::MixIn;

use strict;
use warnings;

use base 'ObjectDB::Base';

sub import {
    my $class = shift;
    my $target_class = (caller)[0];

    no strict 'refs';

    my $symtable = \%{"$class\::"};

    foreach my $method (keys %$symtable) {
        next if $method =~ m/^(?:ISA|isa|BEGIN|import|_)/;

        *{"${target_class}::$method"} = \&{"$class\::$method"};
    }
}

1;
