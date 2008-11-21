package ObjectDB;

use strict;
use warnings;

use base 'ObjectDB::Base';

use DBI;
use ObjectDB::Meta;

sub dbh {
    my $self = shift;

    return $self->{dbh} if $self->{dbh};

    my $dbh = DBI->connect('dbi:SQLite:table.db');

    die $DBI::errorstr unless $dbh;

    return $self->{dbh} = $dbh;
}

sub meta {
    my $class = shift;

    if (ref $class) {
        die 'not yet =/';
    }

    return $ObjectDB::Meta::objects{$class} ||=
      ObjectDB::Meta->new($class, @_);
}

sub column {
    my $self = shift;

    $self->{_columns} ||= {};

    if (@_ == 1) {
        return $self->{_columns}->{$_[0]};
    } elsif (@_ == 2) {
        $self->{_columns}->{$_[0]} = $_[1];
    }

    return $self;
}

sub create {
    my $self = shift;
    $self->dbh;

    if (@_ == 1) {
    }
}

sub find {}

sub update {}

sub delete {}

1;
