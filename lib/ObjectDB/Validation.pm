package ObjectDB::Validation;

use strict;
use warnings;

use base 'ObjectDB::MixIn';

sub is_valid {
    my $self = shift;

    $self->error(undef);

    my $errors = 0;
    foreach my $col ($self->meta->columns) {
        my $options = $self->meta->_columns->{$col};

        $errors++ unless _is_valid_null($self, $col);

        if (%$options) {
            $errors++ unless _is_valid_length($self, $col);
            $errors++ unless _is_valid_regex($self, $col);
        }

        $errors++ if !$errors && !_is_valid_unique($self, $col);
    }

    return $errors ? 0 : 1;
}

sub _is_valid_unique {
    my $self = shift;
    my $col = shift;

    return 1 unless $self->meta->is_unique_key($col);

    my $clone = $self->new($col => $self->column($col))->find;
    return 1 unless $clone;

    my @primary_keys = $self->meta->primary_keys;

    foreach my $pk (@primary_keys) {
        if (!defined $self->column($pk)
            || !defined $clone->column($pk)
            || $self->column($pk) ne $clone->column($pk))
        {
            $self->error({}) unless $self->error;
            $self->error->{$col} ||= [];
            push @{$self->error->{$col}}, 'unique';

            return 0;
        }
    }

    return 1;
}

sub _is_valid_regex {
    my $self = shift;
    my $col  = shift;

    if (my $regex = $self->meta->_columns->{$col}->{regex}) {
        unless ($self->column($col) =~ qr/^$regex$/) {
            $self->error({}) unless $self->error;
            $self->error->{$col} ||= [];
            push @{$self->error->{$col}}, 'regex';
            return 0;
        }
    }

    return 1;
}

sub _is_valid_length {
    my $self = shift;
    my $col = shift;

    if (my $length = $self->meta->_columns->{$col}->{length}) {
        my $max_length;
        my $min_length;
        if (ref $length eq 'ARRAY') {
            $min_length = $length->[0];
            $max_length = $length->[1];
        } else {
            $min_length = 0;
            $max_length = $length;
        }

        return 1 if $min_length == 0 && not defined $self->column($col);

        if (   length $self->column($col) < $min_length
            || length $self->column($col) > $max_length)
        {
            $self->error({}) unless $self->error;
            $self->error->{$col} ||= [];
            push @{$self->error->{$col}}, 'length';

            return 0;
        }
    }

    return 1;
}

sub _is_valid_null {
    my $self = shift;
    my $col = shift;

    return 1 if $self->meta->is_auto_increment($col);

    return 1 if $self->meta->_columns->{$col}->{is_null};

    unless (defined $self->column($col) && $self->column($col) ne '') {
        $self->error({}) unless $self->error;
        $self->error->{$col} ||= [];
        push @{$self->error->{$col}}, 'null';
        return 0;
    }

    return 1;
}

1;
