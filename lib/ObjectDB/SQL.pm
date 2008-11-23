package ObjectDB::SQL;

use strict;
use warnings;

use base 'ObjectDB::Base';

use overload '""' => sub { shift->to_string }, fallback => 1;

__PACKAGE__->attr('_command', chained => 1);

our $AUTOLOAD;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    my %params = @_;

    $self->command(delete $params{command}, @_);

    return $self;
}

sub command {
    my $self = shift;
    my ($command) = shift;

    return unless $command;

    my $class = __PACKAGE__ . '::' . ucfirst $command;
    eval "require $class;";

    die "command $class is unknown: $@" if $@;

    $self->_command($class->new(_parent => $self, @_));

    return $self;
}

sub _where_to_string {
    my $self = shift;
    my ($where) = @_;

    my $string = "";

    if (ref $where eq 'HASH') {
        foreach my $key (keys %$where) {
            $string .= "$key = '$where->{$key}'";
        }
    } else {
        $string .= $where;
    }

    return $string;
}

sub to_string {
    my $self = shift;

    return "" unless $self->_command;

    return $self->_command->to_string;
}

sub AUTOLOAD {
    my $self = shift;

    return unless $self->_command;

    my $method = $AUTOLOAD;
    $method =~ s/.*://;

    $self->_command->$method(@_) unless $method eq 'DESTROY';
}

1;
