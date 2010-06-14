package ObjectDB::Chain::Count;

use strict;
use warnings;

use base 'ObjectDB::Chain';

use ObjectDB::SQL;

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{sql} = ObjectDB::SQL->build('select');

    my $table = $self->parent->schema->table;
    my @pk    = map {"`$table`.`$_`"} $self->parent->schema->primary_keys;
    my $pk    = join(',', @pk);

    $self->sql->source($table);
    $self->sql->columns(\"COUNT(DISTINCT $pk)");

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

    warn "$sql" if $ENV{OBJECTDB_DEBUG};

    my $hash_ref = $dbh->selectrow_hashref("$sql", {}, @{$sql->bind});
    unless ($hash_ref && ref $hash_ref eq 'HASH') {
        $self->error($dbh->errstr);
        return;
    }

    my @values = values %$hash_ref;
    return shift @values;
}

1;
