package ObjectDB::Chain::DeleteRelated;

use strict;
use warnings;

use base 'ObjectDB::Chain';

use ObjectDB::SQL;

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{sql} = ObjectDB::SQL->build('delete');

    $self->sql->table($self->parent->schema->table);

    return $self;
}

sub name { @_ > 1 ? $_[0]->{name} = $_[1] : $_[0]->{name} }

sub where {
    my $self = shift;

    if (@_) {
        my $where = $self->_resolve_columns(@_);
        $self->sql->where($where);
    }

    return $self;
}

sub process {
    my $self = shift;

    my $dbh  = $self->init_db;
    my $sql  = $self->sql;
    my $name = $self->name;

    my $where = $sql->where;
    $where ||= [];

    my $relationship = $self->parent->_load_relationship($name);

    my $class_param = 'class';
    if ($relationship->{type} eq 'many to many') {
        my $map_from = $relationship->{map_from};
        my $map_to   = $relationship->{map_to};

        my ($to, $from) =
          %{$relationship->map_class->schema->relationships->{$map_from}
              ->{map}};

        for (my $i = 0; $i < @$where; $i += 2) {
            $where->[$i] = "$map_to." . $where->[$i];
        }

        push @$where, ($to => $self->parent->column($from));

        $class_param = 'map_class';
    }
    else {
        my ($from, $to) = %{$relationship->{map}};

        push @$where, ($to => $self->parent->column($from));
    }

    if ($relationship->where) {
        push @$where, @{$relationship->where};
    }

    my $rel = $relationship->$class_param->new;
    $rel->init_db($dbh);

    my $ok;
    if ($self->parent->chained) {
        $ok = $rel->delete->where($where)->process;
    }
    else {
        $ok = $rel->delete(where => $where);
    }
    return $ok unless $ok;

    # Do nothing if no preloaded objects found
    my $related = $self->parent->_related->{$name};
    return $ok unless $related;

    # Remove deleted objects from parent object
    my $objects = [];
    $related = [$related] unless ref($related) eq 'ARRAY';

    my %where = @$where;
    if ($relationship->type eq 'many to many') {
        my ($to, $from) =
          %{$relationship->map_class->schema->relationships->{$relationship->{map_from}}
              ->{map}};
        delete $where{$to};

        # Remove everything if we don't have any specific columns
        unless (%where) {
            delete $self->parent->_related->{$name};
            return $ok;
        }

        # Cut off prefixes
        foreach my $key (keys %where) {
            my $v = delete $where{$key};
            $key =~ s/^.*?\.//;
            $where{$key} = $v;
        }
    }

    OBJECT: foreach my $rel (@$related) {
        foreach my $arg (keys %where) {
            my $value = $rel->column($arg);

            next OBJECT if defined $value && $value eq $where{$arg};
        }

        push @$objects, $rel;
    }

    if (@$objects) {
        $self->parent->_related->{$name} = $objects;
    }
    else {
        delete $self->parent->_related->{$name};
    }

    return $ok;
}

1;
