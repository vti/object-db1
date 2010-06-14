package ObjectDB::Chain::Find;

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

    # Default page size
    $self->{page_size} = 10;

    return $self;
}

sub single {
    @_ > 1 ? do { $_[0]->{single} = $_[1]; $_[0] } : $_[0]->{single};
}

sub page {
    @_ > 1 ? do { $_[0]->{page} = $_[1]; $_[0] } : $_[0]->{page};
}

sub page_size {
    @_ > 1 ? do { $_[0]->{page_size} = $_[1] if defined $_[1]; $_[0] } : $_[0]->{page_size};
}

sub iterator {
    @_ > 1 ? do { $_[0]->{iterator} = $_[1]; $_[0] } : $_[0]->{iterator};
}

sub columns {
    my $self = shift;

    if (@_) {
        $self->sql->columns(@_);
    }

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

sub order_by {
    my $self = shift;

    if (@_) {
        my $order_by = $self->_resolve_order_by(@_);
        $self->sql->order_by($order_by);
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

    # Default columns are all the schema columns
    unless ($sql->columns > $self->parent->schema->primary_keys) {

        # Switch to the original table columns
        $sql->source($self->parent->schema->table);
        $sql->columns($self->parent->schema->columns);
    }

    unless ($self->single) {
        if (defined(my $page = $self->page)) {
            $page = 1 unless $page && $page =~ m/^[0-9]+$/o;
            $sql->offset(($page - 1) * $self->page_size);
            $sql->limit($self->page_size);
        }
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

    if ($self->iterator) {
        return ObjectDB::Iterator->new(
            object => $self->parent,
            sth    => $sth,
            sql    => $sql
        );
    }
    else {
        my $rows = $sth->fetchall_arrayref;
        return $self->single ? undef : [] unless $rows && @$rows;

        my $objects = $self->parent->_map_rows_to_objects(
            rows    => $rows,
            sql     => $sql
        );

        return $self->single ? $objects->[0] : wantarray ? @$objects : $objects;
    }
}

sub _resolve_order_by {
    my $self = shift;
    my $order_by = shift;

    return unless $order_by;

    my $class = ref($self->parent);

    my @parts = split /\s*,\s*/ => $order_by;

    foreach my $part (@parts) {
        my $relationships = $class->schema->relationships;
        while ($part =~ s/^(\w+)\.//) {
            my $prefix = $1;

            if (my $relationship = $relationships->{$prefix}) {
                my $rel_table = $relationship->related_table;
                $part = "$rel_table.$part";

                $relationships = $relationship->class->schema->relationships;
            }
        }
    }

    return $self->sql->order_by(join(', ', @parts));
}

1;
