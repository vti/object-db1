package ObjectDB::Iterator;

use strict;
use warnings;

use base 'ObjectDB::Base';

__PACKAGE__->attr('sth', chained => 1);
__PACKAGE__->attr('class', chained => 1);

sub next {
    my $self = shift;
    
    return unless $self->sth;

    my $hash_ref = $self->sth->fetchrow_hashref;

    return unless $hash_ref;

    return $self->class->new(%$hash_ref);
}

1;
