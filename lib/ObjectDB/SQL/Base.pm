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

sub driver { @_ > 1 ? $_[0]->{driver} = $_[1] : $_[0]->{driver} }
sub bind   { @_ > 1 ? $_[0]->{bind}   = $_[1] : $_[0]->{bind} }

sub _string { @_ > 1 ? $_[0]->{_string} = $_[1] : $_[0]->{_string} }

sub _where_string {
    @_ > 1 ? $_[0]->{_where_string} = $_[1] : $_[0]->{_where_string};
}

sub merge {
    my $self   = shift;
    my %params = @_;

    foreach my $key (keys %params) {
        $self->$key($params{$key});
    }

    return $self;
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
