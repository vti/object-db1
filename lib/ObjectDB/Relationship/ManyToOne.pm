package ObjectDB::Relationship::ManyToOne;

use strict;
use warnings;

use base 'ObjectDB::Relationship';

__PACKAGE__->attr([qw/ map /]);

sub to_source {
    my $self = shift;

    my $table     = $self->orig_class->meta->table;
    my $rel_table = $self->class->meta->table;

    my ($from, $to) = %{$self->{map}};

    return {
        name       => $rel_table,
        join       => 'left',
        constraint => {"$rel_table.$to" => "$table.$from"}
    };
}

1;
