package ObjectDB::Relationship::OneToMany;

use strict;
use warnings;

use base 'ObjectDB::Relationship';

__PACKAGE__->attr([qw/ class map where /]);

1;
