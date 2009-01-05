package ObjectDB::SQL;

use strict;
use warnings;

use overload '""' => sub { shift->to_string }, fallback => 1;

use base 'ObjectDB::Base';

sub merge {
    my $self = shift;
    my %params = @_;

    foreach my $key (keys %params) {
        $self->$key($params{$key});
    }

    return $self;
}

sub _where_to_string {
    my $self = shift;
    my ($where) = @_;

    my $string = "";

    if (ref $where eq 'ARRAY') {
        my $count = 0;
        while (my ($key, $value) = @{$where}[$count, $count + 1]) {
            last unless $key;

            $value = '' unless defined $value;

            if (ref $key eq 'SCALAR') {
                $string .= $$key;

                $count++;
            } else {
                $string .= ' AND ' unless $count == 0;

                if ($key =~ s/\.(\w+)$//) {
                    my $col = $1;
                    $key .= ".`$col`";
                } else {
                    $key = "`$key`";
                }

                $string .= "$key = '$value'";

                $count += 2;
            }
        }
    } else {
        $string .= $where;
    }

    return "($string)";
}

sub to_string {
    my $self = shift;

    die 'must be overloaded';
}

1;
