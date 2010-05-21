package ObjectDB::SQL::Base;

use strict;
use warnings;

use overload '""' => sub { shift->to_string }, fallback => 1;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{bind} ||= [];

    return $self;
}

sub class  { @_ > 1 ? $_[0]->{class}  = $_[1] : $_[0]->{class} }
sub driver { @_ > 1 ? $_[0]->{driver} = $_[1] : $_[0]->{driver} }
sub bind   { @_ > 1 ? $_[0]->{bind}   = $_[1] : $_[0]->{bind} }

sub _string { @_ > 1 ? $_[0]->{_string} = $_[1] : $_[0]->{_string} }

sub _where_string {
    @_ > 1 ? $_[0]->{_where_string} = $_[1] : $_[0]->{_where_string};
}

sub _where_to_string {
    my $self = shift;
    my ($where, $default_prefix) = @_;

    return $self->_where_string if $self->_where_string;

    my $string = "";

    my $bind = $self->bind;

    if (ref $where eq 'ARRAY') {
        my $count = 0;
        while (my ($key, $value) = @{$where}[$count, $count + 1]) {
            last unless $key;

            my $logic = $self->where_logic || 'AND';
            $string .= " $logic " unless $count == 0;

            if (ref $key eq 'SCALAR') {
                $string .= $$key;

                $count++;
            }
            else {
                if ($key =~ s/^-//) {
                    if ($key eq 'or' || $key eq 'and') {
                        $self->where_logic(uc $key);
                        $string .= $self->_where_to_string($value);
                        last;
                    }
                }

                if ($key =~ s/\.(\w+)$//) {
                    my $col = $1;
                    $key = "`$key`.`$col`";
                }
                elsif ($default_prefix) {
                    $key = "`$default_prefix`.`$key`";
                }
                else {
                    $key = "`$key`";
                }

                if (defined $value) {
                    if (ref $value eq 'HASH') {
                        my ($op, $val) = %$value;

                        if (defined $val) {
                            $string .= "$key $op ?";
                            push @$bind, $val;
                        }
                        else {
                            $string .= "$key IS $op NULL";
                        }
                    }
                    elsif (ref $value eq 'ARRAY') {
                        $string .= "$key IN (";

                        my $first = 1;
                        foreach my $v (@$value) {
                            $string .= ', ' unless $first;
                            $string .= '?';
                            $first = 0;

                            push @$bind, $v;
                        }

                        $string .= ")";
                    }
                    else {
                        $string .= "$key = ?";
                        push @$bind, $value;
                    }
                }
                else {
                    $string .= "$key IS NULL";
                }

                $count += 2;
            }
        }
    }
    else {
        $string .= $where;
    }

    return unless $string;

    $self->bind($bind);

    return $self->_where_string("($string)");
}

sub to_string {
    my $self = shift;

    die 'must be overloaded';
}

sub _resolve_columns {
    my $self = shift;

    my $where = $self->where;
    my $class = $self->class;
    return unless $where;

    if (ref $where eq 'ARRAY') {
        my $count = 0;
        while (my ($key, $value) = @{$where}[$count, $count + 1]) {
            last unless $key;

            if (ref $key eq 'SCALAR') {
                $count++;
            }
            else {
                my $relationships = $class->schema->relationships;
                while ($key =~ s/^(\w+)\.//) {
                    my $prefix = $1;

                    if (my $relationship = $relationships->{$prefix}) {
                        if ($relationship->type eq 'many to many') {
                            $self->source($relationship->to_map_source);
                        }

                        $self->source(
                            $relationship->to_source
                        );

                        my $rel_name = $relationship->class->schema->table;
                        $where->[$count] = "$rel_name.$key";

                        $relationships =
                          $relationship->class->schema->relationships;
                    }
                }

                $count += 2;
            }
        }
    }

    return $self;
}


sub _resolve_with {
    my $self = shift;
    return unless @_;

    my ($with) = @_;
    my $class = $self->class;

    my @new_rel_info;

    foreach my $rel_info (@$with) {
        unless (ref $rel_info eq 'HASH') {
            $rel_info = {name => $rel_info};
        }

        my $relationship;
        my $relationships = $class->schema->relationships;
        my $last          = 0;
        my $name;
        my $last_rel;
        while (1) {
            if ($rel_info->{name} =~ s/^(\w+)\.//) {
                $name = $1;

                $rel_info->{subwith} = $name;
            }
            else {
                $name = $rel_info->{name};
                $last = 1;
            }

            unless ($relationship = $relationships->{$name}) {
                die $class . ": unknown relationship '$name'";
            }

            if ($relationship->type eq 'many to many') {
                $self->source($relationship->to_map_source);
            }

            my $success = $self->source($relationship->to_source);

            if ( $last && $success ) {
                my @columns;
                if ($rel_info->{columns}) {
                    $rel_info->{columns} = [$rel_info->{columns}]
                      unless ref $rel_info->{columns} eq 'ARRAY';

                    unshift @{$rel_info->{columns}},
                      $relationship->class->schema->primary_keys;
                }
                else {
                    $rel_info->{columns} =
                      [$relationship->class->schema->columns];
                }

                $self->columns(@{$rel_info->{columns}});

                last;
            }
            elsif ( $last && !$success ){
                last;
            }
            elsif ( $success ) {
                my $new_sub_with = $last_rel if $last_rel;
                my $new_rel_info = {
                    name => $name,
                    subwith => $new_sub_with,
                    columns => [$relationship->class->schema->columns]
                };

                unshift @new_rel_info, $new_rel_info if $success;

                $self->columns($relationship->class->schema->columns) if $success;

            }
            $relationships = $relationship->class->schema->relationships;
            $last_rel = $name;

        }
    }

    foreach my $new_rel_info ( @new_rel_info ){
        unshift @$with, $new_rel_info;
    }

}

sub _resolve_order_by {
    my $self = shift;

    my $class = $self->class;

    my $order_by = $self->order_by;
    return unless $order_by;

    my @parts = split /\s*,\s*/ => $order_by;

    foreach my $part (@parts) {
        my $relationships = $class->schema->relationships;
        while ($part =~ s/^(\w+)\.//) {
            my $prefix = $1;

            if (my $relationship = $relationships->{$prefix}) {
                my $rel_table = $relationship->related_table;
                $part = "$rel_table.$part";

                $relationships = $relationship->class->schema->relationships;
            }
        }
    }

    $self->order_by(join(', ', @parts));

    return $self;
}



1;
__END__

=head1 NAME

ObjectDB::SQL::Base - a base sql generator class for ObjectDB

=head1 SYNOPSIS

Used internally.

=head1 DESCRIPTION

This is a base sql generator class for L<ObjectDB>.

=head1 ATTRIBUTES

=head2 C<bind>

Holds bind arguments.

=head1 METHODS

=head2 C<merge>

Merges sql params.

=head2 C<to_string>

Converts instance to string.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
