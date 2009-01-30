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

    my $constraint = ["$rel_table.$to" => "$table.$from"];

    if ($self->join_args) {
        my $i = 0;
        foreach my $value (@{$self->join_args}) {
            if ($i++ % 2) {
                push @$constraint, $value;
            } else {
                push @$constraint, "$rel_table.$value";
            }
        }
    }

    return {
        name       => $rel_table,
        join       => 'left',
        constraint => $constraint
    };
}

1;
