package ObjectDB::Relationship;

use strict;
use warnings;

use base 'ObjectDB::Base';

__PACKAGE__->attr([qw/ type _orig_class _class /]);

sub new {
    my $class = shift;
    my %params = @_;

    my $self = $class->SUPER::new(
        @_,
        _orig_class => delete $params{orig_class},
        _class      => delete $params{class}
    );
    
    return $self;
}

sub orig_class {
    my $self = shift;

    my $orig_class = $self->_orig_class;

    unless ($orig_class->can('isa')) {
        eval "require $orig_class;";
    }

    return $orig_class;
}

sub class {
    my $self = shift;

    my $class = $self->_class;

    unless ($class->can('isa')) {
        eval "require $class;";
    }

    return $class;
}

sub related_table {
    my $self = shift;

    return $self->class->meta->table;
}

1;
