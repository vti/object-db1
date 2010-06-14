package ObjectDB::Chain::FindAndDelete;

use strict;
use warnings;

use base 'ObjectDB::Chain';

use ObjectDB::SQL;
use ObjectDB::Iterator;

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{sql} = ObjectDB::SQL->build('select');

    my $table = $self->parent->schema->table;
    $self->sql->source($table);

    # Primary keys are always fetched
    $self->sql->columns($self->parent->schema->primary_keys);

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

    # Default columns are all the schema columns
    unless ($sql->columns > $self->parent->schema->primary_keys) {

        # Switch to the original table columns
        $sql->source($self->parent->schema->table);
        $sql->columns($self->parent->schema->columns);
    }

    warn "$sql" if $ENV{OBJECTDB_DEBUG};

    my $sth = $dbh->prepare("$sql");
    unless ($sth) {
        $self->error($DBI::errstr);
        return;
    }

    my $rv = $sth->execute(@{$sql->bind});
    unless ($rv) {
        $self->error($DBI::errstr);
        return;
    }

    my $rows = $sth->fetchall_arrayref;
    return 0 unless $rows && @$rows;

    my $objects = $self->parent->_map_rows_to_objects(
        rows    => $rows,
        sql     => $sql
    );

    return 0 unless $objects && @$objects;

    my $count = 0;
    foreach my $object (@$objects) {
        $object->init_db($self->init_db);
        return unless $object->delete;

        $count++;
    }

    return $count;
}

1;
