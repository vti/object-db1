package ObjectDB::Relationship::ManyToOne;

use strict;
use warnings;

use base 'ObjectDB::Relationship';

__PACKAGE__->attr([qw/ _class map /]);

sub new {
    my $class = shift;
    my %params = @_;

    my $self = $class->SUPER::new(@_, _class => delete $params{class});
    
    return $self;
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

sub to_source {
    my $self = shift;

    my $table     = $self->orig_class->meta->table;
    my $rel_table = $self->class->meta->table;

    my ($from, $to) = %{$self->{map}};

    return {
        name       => $rel_table,
        join       => 'left',
        constraint => "$rel_table.$to=$table.$from"
    };
}

1;
