package ObjectDB;

use strict;
use warnings;

use base 'ObjectDB::Base';

use DBI;
use ObjectDB::SQLBuilder;
use ObjectDB::Meta;
use ObjectDB::Iterator;

use constant DEBUG => $ENV{OBJECTDB_DEBUG} || 0;

__PACKAGE__->attr([qw/ is_in_db is_modified /], default => 0);
__PACKAGE__->attr('iterator');
__PACKAGE__->attr('_relationships', default => sub { {} });

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    $self->init(@_);
    $self->is_modified(0);

    return $self;
}

sub init {
    my $self = shift;

    $self->{_columns} ||= {};

    my %values = ref $_[0] ? %{$_[0]} : @_;
    foreach my $key ($self->meta->columns) {
        if (exists $values{$key}) {
            $self->{_columns}->{$key} = delete $values{$key};
        }
        elsif (!defined $self->column($key)
            && defined(my $default = $self->meta->_columns->{$key}->{default})
          )
        {
            $self->{_columns}->{$key} =
              ref $default ? $default->() : $default;
        }
    }

    if ($self->meta->relationships) {
        foreach my $rel (%{$self->meta->relationships}) {
            if (exists $values{$rel}) {
                $self->_relationships->{$rel} = $values{$rel};
            }
        }
    }

    # fake columns
    $self->{_columns}->{$_} = $values{$_} foreach (keys %values);

    $self->is_modified(1);

    return $self;
}

sub init_db {
    my $self = shift;

    die 'init_db method must be overloaded';
}

sub meta {
    my $class = shift;

    if (ref $class) {
        return $ObjectDB::Meta::objects{ref $class} ||=
          ObjectDB::Meta->new(ref $class, @_);
    }

    return $ObjectDB::Meta::objects{$class} ||=
      ObjectDB::Meta->new($class, @_);
}

sub columns {
    my $self = shift;

    my @columns;
    foreach my $key ($self->meta->columns) {
        if (exists $self->{_columns}->{$key}) {
            push @columns, $key;
        }
        elsif (
            defined(my $default = $self->meta->_columns->{$key}->{default}))
        {
            $self->{_columns}->{$key} = $default;
            push @columns, $key;
        }
    }

    return @columns;
}

sub column {
    my $self = shift;

    $self->{_columns} ||= {};

    if (@_ == 1) {
        return defined $_[0] ? $self->{_columns}->{$_[0]} : undef;
    } elsif (@_ == 2) {
        if (defined $self->{_columns}->{$_[0]} && defined $_[1]) {
            $self->is_modified(1) if $self->{_columns}->{$_[0]} ne $_[1];
        }

        $self->{_columns}->{$_[0]} = $_[1];
    }

    return $self;
}

sub clone {
    my $self = shift;

    my %data;
    foreach my $column ($self->meta->columns) {
        next
          if $self->meta->is_primary_key($column)
              || $self->meta->is_unique_key($column);
        $data{$column} = $self->column($column);
    }

    return (ref $self)->new(%data);
}

sub _process_related {
    my $self = shift;

    if ($self->meta->relationships) {
        foreach my $rel (keys %{$self->meta->relationships}) {
            if (my $rel_values = $self->_relationships->{$rel}) {
                if ($self->meta->relationships->{$rel}->{type} eq 'many to many') {
                    $self->set_related($rel, $rel_values);
                } else {
                    my $objects;

                    if (ref $rel_values eq 'ARRAY') {
                        $objects = $rel_values;
                    } elsif (ref $rel_values eq 'HASH') {
                        $objects = [$rel_values];
                    } else {
                        die "wrong params when setting '$rel' relationship: $rel_values";
                    }

                    foreach my $object (@$objects) {
                        $self->create_related($rel, %$object);
                    }
                }
            }
        }
    }
}

sub begin {
    my $self = shift;

    my $dbh = $self->init_db;

    my $sql = ObjectDB::SQLBuilder->build('begin')->merge(@_);

    warn "$sql" if DEBUG;

    return $dbh->do("$sql");
}

sub rollback {
    my $self = shift;

    my $dbh = $self->init_db;

    my $sql = ObjectDB::SQLBuilder->build('rollback');

    warn "$sql" if DEBUG;

    return $dbh->do("$sql");
}

sub commit {
    my $self = shift;

    my $dbh = $self->init_db;

    my $sql = ObjectDB::SQLBuilder->build('commit');

    warn "$sql" if DEBUG;

    return $dbh->do("$sql");
}

sub create {
    my $self = shift;

    return $self if $self->is_in_db;

    my $dbh = $self->init_db;

    my $sql =
      ObjectDB::SQLBuilder->build('insert')->table($self->meta->table)
      ->columns([$self->columns]);

    my @values = map { $self->column($_) } $self->columns;

    warn "$sql" if DEBUG;

    my $sth = $dbh->prepare("$sql");
    my $rv = $sth->execute(@values);

    return unless $rv;

    if (my $auto_increment = $self->meta->auto_increment) {
        $self->column($auto_increment => $dbh->last_insert_id(undef, undef,
                $self->meta->table, $auto_increment));
    }

    $self->is_in_db(1);
    $self->is_modified(0);

    $self->_process_related;

    return $self;
}

sub find {
    my $self = shift;
    my %params = @_;

    my @columns;
    foreach my $name ($self->columns) {
        push @columns, $name
          if $self->meta->is_primary_key($name)
              || $self->meta->is_unique_key($name);
    }

    die "no primary or unique keys specified" unless @columns;

    my $sql = ObjectDB::SQLBuilder->build('select');

    $sql->source($self->meta->table)
      ->columns($self->meta->columns)
      ->where([map { $_ => $self->column($_) } @columns]);

    my $with = $params{with};
    if ($with) {
        $self->_resolve_with($sql, $with);
    }

    warn "$sql" if DEBUG;

    my $dbh = $self->init_db;

    my $sth = $dbh->prepare("$sql");
    $sth->execute(@{$sql->bind});

    my $results = $sth->fetchall_arrayref;
    return unless $results && @$results;

    $self->_map_row_to_object(
        row     => $results->[0],
        columns => [$sql->columns],
        with    => $with,
        object => $self
    );

    $self->is_modified(0);
    $self->is_in_db(1);

    return $self;
}

sub update {
    my $self = shift;

    die 'must be called on instance' unless ref $self;

    return $self unless $self->is_modified;

    my $dbh = $self->init_db;

    my %params = map { $_ => $self->column($_) } $self->meta->primary_keys;

    my @columns = grep { !$self->meta->is_primary_key($_)} $self->meta->columns;
    my @values = map { $self->column($_) } @columns;

    my $sql =
      ObjectDB::SQLBuilder->build('update')->table($self->meta->table)
      ->columns(\@columns)->bind(\@values)->where([%params]);

    warn $sql if DEBUG;

    my $sth = $dbh->prepare("$sql");
    my $rv = $sth->execute(@{$sql->bind});

    $self->_process_related;

    return $rv;
}

sub delete {
    my $self = shift;

    my %params = map { $_ => $self->column($_) } $self->meta->primary_keys;

    my @names = keys %params;

    die "specify primary keys or at least one unique key"
      unless grep {defined $params{$_}} @names;

    foreach my $name (@names) {
        die "$name is not primary key or unique column"
          unless $self->meta->is_primary_key($name)
              || $self->meta->is_unique_key($name);
    }

    my $dbh = $self->init_db;

    my $sql =
      ObjectDB::SQLBuilder->build('delete')->table($self->meta->table)
      ->where([%params]);

    warn $sql if DEBUG;

    my $sth = $dbh->prepare("$sql");

    my $rv = $sth->execute(@{$sql->bind});
    return if $rv eq '0E0';

    return $rv;
}

sub find_objects {
    my $class = shift;
    my %params = @_;

    my $single = delete $params{single};

    my @columns;
    if (my $cols = delete $params{columns}) {
        @columns = ref $cols ? @$cols : ($cols);

        unshift @columns, $class->meta->primary_keys;
    } else {
        @columns = $class->meta->columns;
    }

    my $sql =
      ObjectDB::SQLBuilder->build('select')->source($class->meta->table)
      ->columns(@columns);

    my $page = delete $params{page};
    my $page_size = delete $params{page_size} || 10;

    unless ($single) {
        if (defined $page) {
            $page = 1 unless $page =~ m/[0-9]+/;
            $sql->offset(($page - 1) * $page_size);
            $sql->limit($page_size);
        }
    }

    if (my $sources = delete $params{source}) {
        foreach my $source (@$sources) {
            $sql->source($source);
        }
    }

    my $with;
    if ($with = delete $params{with}) {
        $class->_resolve_with($sql, $with);
    }

    $sql->merge(%params);

    $class->_resolve_columns($sql);

    my $dbh = $class->init_db;

    if ($single || wantarray) {
        $sql->limit(1) if $single;

        warn $sql if DEBUG;

        my $sth = $dbh->prepare("$sql");
        $sth->execute(@{$sql->bind});

        my $results = $sth->fetchall_arrayref;
        return unless $results && @$results;

        my @objects;
        foreach my $row (@$results) {
            my $object = $class->_map_row_to_object(
                row     => $row,
                columns => [$sql->columns],
                with    => $with
            );

            push @objects, $object;
        }
        return $single ? $objects[0] : @objects;
    } else {
        warn $sql if DEBUG;

        my $sth = $dbh->prepare("$sql");

        $sth->execute(@{$sql->bind});

        ObjectDB::Iterator->new(with => $with, sth => $sth, class => $class);
    }
}

sub update_objects {
    my $class = shift;

    my $dbh = $class->init_db;

    my $sql =
      ObjectDB::SQLBuilder->build('update')->table($class->meta->table)
      ->merge(@_);

    unless (@{$sql->columns}) {
        $sql->columns([grep { !$class->meta->is_primary_key($_) }
                      $class->meta->columns]);
    }

    warn "$sql: " . join(', ', @{$sql->bind}) if DEBUG;

    return $dbh->do("$sql", undef, @{$sql->bind});
}

sub delete_objects {
    my $class = shift;

    my $dbh = $class->init_db;

    my $sql =
      ObjectDB::SQLBuilder->build('delete')->table($class->meta->table)
      ->merge(@_);

    $class->_resolve_columns($sql);

    warn $sql if DEBUG;

    my $sth = $dbh->prepare("$sql");

    return $sth->execute(@{$sql->bind});
}

sub count_objects {
    my $class = shift;
    my %params = @_;

    my $dbh = $class->init_db;

    my $sql =
      ObjectDB::SQLBuilder->build('select')->source($class->meta->table)
      ->columns(\'COUNT(*) AS count');

    if (my $sources = delete $params{source}) {
        $sql->source($_) foreach @$sources;
    }

    $sql->merge(%params);

    $class->_resolve_columns($sql);

    warn $sql if DEBUG;

    my $hash_ref = $dbh->selectrow_hashref("$sql", {}, @{$sql->bind});

    return $hash_ref->{count};
}

sub _load_relationship {
    my $self = shift;
    my ($name) = @_;

    die "unknown relationship $name"
      unless $self->meta->relationships
          && exists $self->meta->relationships->{$name};

    my $relationship = $self->meta->relationships->{$name};

    if ($relationship->{type} eq 'proxy') {
        my $proxy_key = $relationship->{proxy_key};

        die "proxy_key is required for $name" unless $proxy_key;

        $name = $self->column($proxy_key);

        die "proxy_key '$proxy_key' is empty" unless $name;

        $relationship = $self->meta->relationships->{$name};

        die "unknown relatioship $name" unless $relationship;
    }

    return $relationship;
}

sub create_related {
    my $self = shift;
    my ($name) = shift;

    unless ($self->is_in_db) {
        die "can't create related objects when object is not in db";
    }

    my $relationship = $self->_load_relationship($name);

    unless ($relationship->{type} eq 'one to many'
        || $relationship->{type} eq 'many to many'
        || $relationship->{type} eq 'one to one')
    {
        die
          "can be called only on 'one to many', 'one to one' or 'many to many' relationships";
    }

    if ($relationship->{type} eq 'many to many') {
        if (my $object = $self->find_related($name, single => 1, where => [@_])) {
            return $object;
        }

        my $object = $relationship->class->new(@_)->find;
        unless ($object) {
            $object = $relationship->class->new(@_)->create;
        }

        my $map_from = $relationship->{map_from};
        my $map_to = $relationship->{map_to};

        my ($from_foreign_pk, $from_pk) =
          %{$relationship->{map_class}->meta->relationships->{$map_from}
              ->{map}};

        my ($to_foreign_pk, $to_pk) =
          %{$relationship->{map_class}->meta->relationships->{$map_to}
              ->{map}};

        $relationship->{map_class}->new(
            $from_foreign_pk => $self->column($from_pk),
            $to_foreign_pk   => $object->column($to_pk)
        )->create;

        return $object;
    } else {
        my ($from, $to) = %{$relationship->{map}};

        my @params = ($to => $self->column($from));

        if ($relationship->{where}) {
            my ($column, $value) = %{$relationship->{where}};
            push @params, ($column => $value);
        }

        if (@_ == 1 && ref $_[0]) {
            return $relationship->class->new(%{$_[0]->to_hash}, @params)->create;
        } else {
            return $relationship->class->new(@params, @_)->create;
        }
    }
}

sub related {
    my $self = shift;
    my ($name) = shift;

    return unless $name;

    my $wantarray = wantarray;
    if (my $rel = $self->_relationships->{$name}) {
        if (ref $rel eq 'ARRAY') {
            return @$rel if $wantarray;
        } elsif ($rel->isa('ObjectDB::Iterator')) {
            return $rel unless $wantarray;
        } elsif (ref $rel) {
            return $rel;
        }
    }

    my $objects;

    if ($wantarray) {
        $objects = [];
        @$objects = $self->find_related($name, @_);
    } else {
        $objects = $self->find_related($name, @_);
    }

    $self->_relationships->{$name} = $objects;

    return $wantarray ? @$objects : $objects;
}

sub find_related {
    my $self = shift;
    my ($name) = shift;

    my $relationship = $self->_load_relationship($name);

    my %params = @_;
    $params{where} ||= [];

    if ($relationship->{type} eq 'many to many') {
        my $map_from = $relationship->{map_from};
        my $map_to = $relationship->{map_to};

        my ($to, $from) =
          %{$relationship->{map_class}->meta->relationships->{$map_from}
              ->{map}};

        push @{$params{where}}, ($relationship->map_class->meta->table .  '.' . $to => $self->column($from));

        ($from, $to) =
          %{$relationship->{map_class}->meta->relationships->{$map_to}
              ->{map}};

        my $table = $relationship->class->meta->table;
        my $map_table = $relationship->{map_class}->meta->table;
        $params{source} = [
            {   name     => $map_table,
                join       => 'left',
                constraint => "$table.$to=$map_table.$from"
            }
        ];
    } else {
        my ($from, $to) = %{$relationship->{map}};

        if (   $relationship->{type} eq 'many to one'
            || $relationship->{type} eq 'one to one')
        {
            $params{single} = 1;

            return unless defined $self->column($from);
        }

        push @{$params{where}}, ($to => $self->column($from));
    }

    if ($relationship->{where}) {
        push @{$params{where}}, %{$relationship->{where}};
    }

    return $relationship->class->find_objects(%params);
}

sub count_related {
    my $self = shift;
    my ($name) = shift;

    my $relationship = $self->_load_relationship($name);

    my %params = @_;
    $params{where} ||= [];

    if ($relationship->{type} eq 'many to many') {
        my $map_from = $relationship->{map_from};
        my $map_to = $relationship->{map_to};

        my ($to, $from) =
          %{$relationship->{map_class}->meta->relationships->{$map_from}
              ->{map}};

        push @{$params{where}}, ($relationship->map_class->meta->table .  '.' . $to => $self->column($from));

        ($from, $to) =
          %{$relationship->{map_class}->meta->relationships->{$map_to}
              ->{map}};

        my $table = $relationship->class->meta->table;
        my $map_table = $relationship->{map_class}->meta->table;
        $params{source} = [
            {   name     => $map_table,
                join       => 'left',
                constraint => "$table.$to=$map_table.$from"
            }
        ];
    } else {
        my ($from, $to) = %{$relationship->{map}};

        push @{$params{where}}, ($to => $self->column($from)),
    }

    if ($relationship->{where}) {
        push @{$params{where}}, %{$relationship->{where}};
    }

    return $relationship->class->count_objects(%params);
}

sub update_related {
    my $self = shift;

    my ($name) = shift;

    my $relationship = $self->_load_relationship($name);

    my %params = @_;

    my ($from, $to) = %{$relationship->{map}};

    my $where = delete $params{where} || [];

    if ($relationship->{where}) {
        push @$where, %{$relationship->{where}};
    }

    return $relationship->class->update_objects(
        where => [$to => $self->column($from), @$where],
        @_
    );
}

sub delete_related {
    my $self = shift;
    my ($name) = shift;

    my $relationship = $self->_load_relationship($name);

    my %params = @_;
    $params{where} ||= [];

    my $class_param = 'class';
    if ($relationship->{type} eq 'many to many') {
        my $map_from = $relationship->{map_from};
        my $map_to = $relationship->{map_to};

        my ($to, $from) =
          %{$relationship->map_class->meta->relationships->{$map_from}
              ->{map}};

        push @{$params{where}}, ($to => $self->column($from));

        $class_param = 'map_class';
    } else {
        my ($from, $to) = %{$relationship->{map}};

        push @{$params{where}}, ($to => $self->column($from));
    }

    if ($relationship->{where}) {
        push @{$params{where}}, %{$relationship->{where}};
    }

    return $relationship->{$class_param}->delete_objects(%params);
}

sub set_related {
    my $self = shift;
    my ($name) = shift;

    my $relationship = $self->_load_relationship($name);

    die "only 'many to many' is supported"
      unless $relationship->{type} eq 'many to many';

    my $objects;

    if (ref $_[0] eq 'ARRAY') {
        $objects = $_[0];
    } elsif (ref $_[0] eq 'HASH') {
        $objects = [$_[0]];
    } elsif (@_ % 2 == 0) {
        $objects = [{@_}];
    } else {
        die 'wrong set_related params';
    }

    $self->delete_related($name);

    foreach my $object (@$objects) {
        $self->create_related($name, %$object);
    }

    return $self;
}

sub _map_row_to_object {
    my $class = shift;
    my %params = @_;

    my $row = $params{row};
    my $with = $params{with};
    my $columns = $params{columns};
    my $o = $params{object};

    my %values = map { $_ => shift @$row } @$columns;

    my $object = $o ? $o->init(%values) : $class->new(%values);

    if ($with) {
        foreach my $name (ref $with eq 'ARRAY' ? @$with : $with) {
            my $relationship = $object->meta->relationships->{$name};

            if ($relationship->{type} eq 'many to one' ||
                $relationship->{type} eq 'one to one') {
                %values = map { $_ => shift @$row } $relationship->class->meta->columns;
                $object->_relationships->{$name} = $relationship->class->new(%values);
            } else {
                die 'not supported';
            }
        }
    }
    
    return $object;
}

sub _resolve_with {
    my $class = shift;
    return unless @_;

    my ($sql, $with) = @_;

    foreach my $name (ref $with eq 'ARRAY' ? @$with : $with) {
        my $rel = $class->_load_relationship($name);

        if ($rel->type eq 'many to one' || $rel->type eq 'one to one') {
            $sql->source($rel->to_source);
        } else {
            die $rel->type . ' is not supported';
        }

        $sql->columns($rel->class->meta->columns);
    }
}

sub _resolve_columns {
    my $self = shift;
    return unless @_;

    my ($sql) = @_;

    my $where = $sql->where;
    return unless $where;

    if (ref $where eq 'ARRAY') {
        my $count = 0;
        while (my ($key, $value) = @{$where}[$count, $count + 1]) {
            last unless $key;

            if (ref $key eq 'SCALAR') {
                $count++;
            } else {
                my $relationships = $self->meta->relationships;
                while ($key =~ s/^(\w+)\.//) {
                    my $prefix = $1;

                    if (my $relationship = $relationships->{$prefix}) {
                        if ($relationship->type eq 'many to many') {
                            $sql->source($relationship->to_map_source);
                        }

                        $sql->source($relationship->to_source);

                        my $rel_table = $relationship->related_table;
                        $where->[$count] = "$rel_table.$key";

                        $relationships =
                          $relationship->class->meta->relationships;
                    }
                }

                $count += 2;
            }
        }
    }

    return $self;
}

sub to_hash {
    my $self = shift;

    #my @columns = $self->columns;
    my @columns = keys %{$self->{_columns}};

    my $hash = {};
    foreach my $key (@columns) {
        $hash->{$key} = $self->column($key);
    }

    foreach my $name (keys %{$self->_relationships}) {
        my $rel = $self->_relationships->{$name};

        if (ref $rel eq 'ARRAY') {
        } elsif ($rel->isa('ObjectDB::Iterator')) {
        } else {
            $hash->{$name} = $rel->to_hash;
        }
    }

    return $hash;
}

1;
