package ObjectDB::Chain::Load;

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

sub columns {
    my $self = shift;

    if (@_) {
        $self->sql->columns(@_);
    }

    return $self;
}

sub with {
    my $self = shift;

    if (@_) {
        my $with = $self->_resolve_with(@_);
        $self->sql->with($with);
    }

    return $self;
}

sub process {
    my $self = shift;

    my $dbh = $self->init_db;
    my $sql = $self->sql;

    my @columns;
    foreach my $name ($self->parent->columns) {
        push @columns, $name
          if $self->parent->schema->is_primary_key($name)
              || $self->parent->schema->is_unique_key($name);
    }

    Carp::croak "->load: no primary or unique keys specified" unless @columns;

    $sql->where([map { $_ => $self->parent->column($_) } @columns]);

    # Default columns are all the schema columns
    unless ($sql->columns > $self->parent->schema->primary_keys) {

        # Switch to the original table columns
        $sql->source($self->parent->schema->table);
        $sql->columns($self->parent->schema->columns);
    }

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
    return unless $rows && @$rows;

    my $object = $self->parent->_map_rows_to_objects(
        rows    => $rows,
        sql     => $sql
    )->[0];

    $self->parent->init(%{$object->to_hash});

    $self->parent->is_in_db(1);
    $self->parent->is_modified(0);

    return $self->parent;
}

1;
