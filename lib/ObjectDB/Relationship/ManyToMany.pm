package ObjectDB::Relationship::ManyToMany;

use strict;
use warnings;

use base 'ObjectDB::Relationship';

__PACKAGE__->attr([qw/ map_class map_from map_to /]);

1;
