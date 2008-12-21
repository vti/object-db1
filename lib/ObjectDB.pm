package ObjectDB;

use strict;
use warnings;

use base 'ObjectDB::Base';

use DBI;
use ObjectDB::SQL;
use ObjectDB::Meta;
use ObjectDB::Iterator;

use constant DEBUG => $ENV{OBJECTDB_DEBUG} || 0;

__PACKAGE__->attr([qw/ is_in_db is_modified not_found /], default => 0);
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
                    die 'not supported yet!';
                }
            }
        }
    }
}

sub create {
    my $class = shift;
    my $self = ref $class ? $class : $class->new(@_);

    return $self if $self->can('is_valid') && !$self->is_valid;

    my $dbh = $self->init_db;

    my $sql = ObjectDB::SQL->new(command => 'insert',
                                 table   => $self->meta->table,
                                 columns => [$self->columns]);

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
    my $class = shift;
    my $self = ref $class ? $class : $class->new(@_);

    my @columns;
    foreach my $name ($self->columns) {
        push @columns, $name
          if $self->meta->is_primary_key($name)
              || $self->meta->is_unique_key($name);
    }

    return $self if $self->can('is_valid') && !$self->is_valid(@columns);

    my $dbh = $class->init_db;

    my $sql = ObjectDB::SQL->new(
        command => 'select',
        source  => $self->meta->table,
        columns => [$self->meta->columns],
        where   => [map { $_ => $self->column($_) } @columns]
    );

    warn $sql if DEBUG;

    my $hash_ref = $dbh->selectrow_hashref("$sql");

    unless (keys %$hash_ref) {
        $self->not_found(1);
        return $self;
    }

    $self->init(%$hash_ref);
    $self->is_modified(0);
    $self->is_in_db(1);

    return $self;
}

sub select {
    my $class = shift;

    my @pk = $class->meta->primary_keys();

    if (@_ >= @pk) {
        $class->find(map { $_ => shift @_ } @pk);
    } else {
        die 'not enough primary keys';
    }
}

sub update {
    my $self = shift;

    die 'must be called on instance' unless ref $self;

    return $self unless $self->is_modified;

    return $self if $self->can('is_valid') && !$self->is_valid;

    my $dbh = $self->init_db;

    my %params = map { $_ => $self->column($_) } $self->meta->primary_keys;

    my @columns = grep { !$self->meta->is_primary_key($_)} $self->meta->columns;

    my $sql = ObjectDB::SQL->new(command => 'update',
                                 table   => $self->meta->table,
                                 columns => \@columns,
                                 where   => [%params]);

    warn $sql if DEBUG;

    my @values = map { $self->column($_) } @columns;

    my $sth = $dbh->prepare("$sql");
    my $rv = $sth->execute(@values);

    $self->_process_related;

    return $rv;
}

sub delete {
    my $class = shift;
    my $self = ref $class ? $class : $class->new();

    return $self if $self->can('is_valid') && !$self->is_valid($self->columns);

    my %params;
    if (ref $class) {
        %params = map { $_ => $self->column($_) } $self->meta->primary_keys;
    } else {
        die 'query params are required' unless @_;

        %params = @_;
    }

    my @names = keys %params;

    foreach my $name (@names) {
        die "$name is not primary key or unique column"
          unless $self->meta->is_primary_key($name)
              || $self->meta->is_unique_key($name);
    }

    my $dbh = $class->init_db;

    my $sql = ObjectDB::SQL->new(command => 'delete',
                                 table   => $class->meta->table,
                                 where   => [%params]);

    warn $sql if DEBUG;

    return $dbh->do("$sql");
}

sub find_objects {
    my $class = shift;
    my %params = @_;

    my $single = delete $params{single};

    my $dbh = $class->init_db;

    my $sql = ObjectDB::SQL->new(command => 'select',
                                 source  => $class->meta->table,
                                 columns => [$class->meta->columns],
                                 %params);

    if ($single) {
        $sql->limit(1);

        warn $sql if DEBUG;

        my $sth = $dbh->prepare("$sql");

        my $results = $dbh->selectall_arrayref("$sql", {Slice => {}});
        return unless @$results;

        return $class->new(%{$results->[0]});
    } elsif (wantarray) {
        warn $sql if DEBUG;

        my $sth = $dbh->prepare("$sql");

        my $results = $dbh->selectall_arrayref("$sql", {Slice => {}});
        return () unless @$results;

        return map { $class->new(%{$_}) } @$results;
    } else {
        warn $sql if DEBUG;

        my $sth = $dbh->prepare("$sql");

        $sth->execute();

        ObjectDB::Iterator->new(sql => $sql, sth => $sth, class => $class);
    }
}

sub update_objects {
    my $class = shift;

    my $dbh = $class->init_db;

    my $sql = ObjectDB::SQL->new(command => 'update',
                                 table   => $class->meta->table,
                                 @_);

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

    my $sql = ObjectDB::SQL->new(command => 'delete',
                                 table   => $class->meta->table,
                                 @_);

    warn $sql if DEBUG;

    return $dbh->do("$sql");
}

sub count_objects {
    my $class = shift;

    my $dbh = $class->init_db;

    my $sql = ObjectDB::SQL->new(command => 'select',
                                 columns => [\'COUNT(*) AS count'],
                                 source  => $class->meta->table,
                                 @_);

    warn $sql if DEBUG;

    my $hash_ref = $dbh->selectrow_hashref("$sql");

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
        $relationship = $self->meta->relationships->{$name};
    }

    my $class;
    
    if ($relationship->{type} eq 'many to many') {
        $class = $relationship->{map_class};
        eval "require $class;";

        $relationship->{class} =
          $class->meta->relationships->{$relationship->{map_to}}->{class};
    }

    $class = $relationship->{class};

    eval "require $class;";

    return $relationship;
}

sub create_related {
    my $self = shift;
    my ($name) = shift;

    my $relationship = $self->_load_relationship($name);

    unless ($relationship->{type} eq 'one to many'
        || $relationship->{type} eq 'many to many')
    {
        die
          "can be called only on 'one to many' or 'many to many' relationships";
    }

    if ($relationship->{type} eq 'many to many') {
        if (my $object = $self->find_related($name, single => 1, where => [@_])) {
            return $object;
        }

        my $map_from = $relationship->{map_from};
        my $map_to = $relationship->{map_to};

        my ($from_foreign_pk, $from_pk) =
          %{$relationship->{map_class}->meta->relationships->{$map_from}
              ->{map}};

        my ($to_foreign_pk, $to_pk) =
          %{$relationship->{map_class}->meta->relationships->{$map_to}
              ->{map}};

        my $object = $relationship->{class}->find(@_);
        if ($object->not_found) {
            $object = $relationship->{class}->create(@_);
        }

        $relationship->{map_class}->create(
            $from_foreign_pk => $self->column($from_pk),
            $to_foreign_pk   => $object->column($to_pk)
        );

        return $object;
    } else {
        my ($from, $to) = %{$relationship->{map}};

        my @params = ($to => $self->column($from));

        if ($relationship->{where}) {
            my ($column, $value) = %{$relationship->{where}};
            push @params, ($column => $value);
        }

        if (@_ == 1 && ref $_[0]) {
            return $relationship->{class}->create(%{$_[0]->to_hash}, @params);
        } else {
            return $relationship->{class}->create(@params, @_);
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
        }

        if ($rel->isa('ObjectDB::Iterator')) {
            return $rel unless $wantarray;
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

        push @{$params{where}}, ($to => $self->column($from));

        ($from, $to) =
          %{$relationship->{map_class}->meta->relationships->{$map_to}
              ->{map}};

        my $table = $relationship->{class}->meta->table;
        my $map_table = $relationship->{map_class}->meta->table;
        $params{source} = [ $table ,
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

    return $relationship->{class}->find_objects(%params);
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

        push @{$params{where}}, ($to => $self->column($from));

        ($from, $to) =
          %{$relationship->{map_class}->meta->relationships->{$map_to}
              ->{map}};

        my $table = $relationship->{class}->meta->table;
        my $map_table = $relationship->{map_class}->meta->table;
        $params{source} = [ $table ,
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

    return $relationship->{class}->count_objects(%params);
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

    return $relationship->{class}->update_objects(
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
          %{$relationship->{map_class}->meta->relationships->{$map_from}
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

sub to_hash {
    my $self = shift;

    my @columns = $self->columns;

    my $hash = {};
    foreach my $key (@columns) {
        $hash->{$key} = $self->column($key);
    }

    return $hash;
}

1;
