package ObjectDB::Chain::Delete;

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

    my $dbh = $self->init_db;
    my $sql = $self->sql;

    my $sth = $dbh->prepare("$sql");
    unless ($sth) {
        $self->error($DBI::errstr);
        return;
    }

    my $rv = $sth->execute(@{$sql->bind});
    unless ($rv && $rv eq '1') {
        $self->error($DBI::errstr);
        return;
    }

    return 1;
}

1;
