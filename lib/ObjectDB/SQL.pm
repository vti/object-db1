package ObjectDB::SQL;

use strict;
use warnings;

use overload '""' => sub { shift->to_string }, fallback => 1;

use base 'ObjectDB::Base';

__PACKAGE__->attr([qw/ bind /], default => sub { [] }, chained => 1);
__PACKAGE__->attr([qw/ _string _where_string /]);

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

    if (ref $where eq 'ARRAY') {
        my $count = 0;
        while (my ($key, $value) = @{$where}[$count, $count + 1]) {
            last unless $key;

            if (ref $key eq 'SCALAR') {
                $string .= $$key;

                $count++;
            }
            else {
                my $logic = $self->where_logic || 'AND';
                $string .= " $logic " unless $count == 0;

                if ($key =~ s/\.(\w+)$//) {
                    my $col = $1;
                    $key .= ".`$col`";
                }
                elsif ($default_prefix) {
                    $key = "$default_prefix.`$key`";
                }
                else {
                    $key = "`$key`";
                }

                if (defined $value) {
                    if (ref $value eq 'HASH') {
                        my ($op, $val) = %$value;

                        $string .= "$key $op ?";
                        push @{$self->bind}, $val;
                    } else {
                        $string .= "$key = ?";
                        push @{$self->bind}, $value;
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

    return $self->_where_string("($string)");
}

sub to_string {
    my $self = shift;

    die 'must be overloaded';
}

1;
