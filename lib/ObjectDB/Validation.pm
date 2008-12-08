package ObjectDB::Validation;

use strict;
use warnings;

use base 'ObjectDB::MixIn';

__PACKAGE__->attr([qw/ _errors /]);

sub errors {
    my $self = shift;

    return _errors($self) if @_ == 0;

    my $col = shift;
    if (@_ == 0) {
        return $self->errors->{$col} if $self->errors;
    } else {
        my $error = shift;

        _errors($self, {}) unless _errors($self);
        $self->errors->{$col} ||= [];
        push @{$self->errors->{$col}}, $error;
    }
}

sub is_valid {
    my $self = shift;
    my $caller = (caller(1))[3] || '';

    $caller =~ s/^.*::// if $caller;

    _errors($self, undef);

    my $errors = 0;
    foreach my $col (@_ ? @_ : $self->meta->columns) {
        my $options = $self->meta->_columns->{$col};

        $errors++ unless _is_valid_null($self, $col);

        if (%$options) {
            $errors++ unless _is_valid_length($self, $col);
            $errors++ unless _is_valid_regex($self, $col);
        }

        if ($caller eq 'create' || $caller eq 'update') {
            $errors++ if !$errors && !_is_valid_unique($self, $col);
        }
    }

    return $errors ? 0 : 1;
}

sub _is_valid_unique {
    my $self = shift;
    my $col = shift;

    return 1 unless $self->meta->is_unique_key($col);

    my $clone = $self->new($col => $self->column($col))->find;
    $self->errors($clone->errors) if $clone->errors;
    return 1 if $clone->not_found;

    my @primary_keys = $self->meta->primary_keys;

    foreach my $pk (@primary_keys) {
        if (!defined $self->column($pk)
            || !defined $clone->column($pk)
            || $self->column($pk) ne $clone->column($pk))
        {
            $self->errors($col => 'unique');
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
            $self->errors($col => 'regex');
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

        if (not defined $self->column($col)) {
            return 1 if $min_length == 0;

            $self->errors($col => 'length');
            return 0;
        }

        if (   length $self->column($col) < $min_length
            || length $self->column($col) > $max_length)
        {
            $self->errors($col => 'length');
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
        $self->errors($col => 'null');
        return 0;
    }

    return 1;
}

1;
