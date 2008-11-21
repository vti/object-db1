package ObjectDB::Iterator;

use strict;
use warnings;

use base 'ObjectDB::Base';

__PACKAGE__->attr('sth');

sub next {
    my $self = shift;
    
    return unless $self->sth;

    return $self->sth->fetchrow_hashref;
}

1;
