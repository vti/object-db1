package ObjectDB::Iterator;

use strict;
use warnings;

use base 'ObjectDB::Base';

__PACKAGE__->attr('step', chained => 1, default => 0);
__PACKAGE__->attr([qw/ class sql sth /], chained => 1);

sub next {
    my $self = shift;

    return unless $self->sth;

    my $hash_ref = $self->sth->fetchrow_hashref;

    return unless $hash_ref;

    $self->step($self->step + 1);

    my $object = $self->class->new(%$hash_ref);

    $object->iterator($self);

    return $object;
}

1;
