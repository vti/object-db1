package ObjectDB;

use strict;
use warnings;

use base 'ObjectDB::Base';

use DBI;
use ObjectDB::SQL;
use ObjectDB::Meta;
use ObjectDB::Iterator;

use constant DEBUG => $ENV{OBJECTDB_DEBUG} || 0;

__PACKAGE__->attr([qw/ is_in_db is_modified /], default => 0);
__PACKAGE__->attr([qw/ error /], default => sub { {} });

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    $self->init(@_);

    return $self;
}

sub init {
    my $self = shift;

    $self->{_columns} ||= {};

    my %values = @_;
    foreach my $key ($self->meta->columns) {
        if (exists $values{$key}) {
            $self->{_columns}->{$key} = $values{$key};
        }
        elsif (
            defined(my $default = $self->meta->_columns->{$key}->{default}))
        {
            $self->{_columns}->{$key} = $default;
        }
    }
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
        return $self->{_columns}->{$_[0]};
    } elsif (@_ == 2) {
        if (defined $self->{_columns}->{$_[0]} && defined $_[1]) {
            $self->is_modified(1) if $self->{_columns}->{$_[0]} ne $_[1];
        }

        $self->{_columns}->{$_[0]} = $_[1];
    }

    return $self;
}

sub create {
    my $class = shift;
    my $self = ref $class ? $class : $class->new(@_);

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

    return $self;
}

sub find {
    my $class = shift;
    my $self = ref $class ? $class : $class->new(@_);
    #my %params = @_;

    #my @names = keys %params;

    foreach my $name ($self->columns) {
        die "$name is not primary key or unique column"
          unless $self->meta->is_primary_key($name)
              || $self->meta->is_unique_key($name);
    }

    my $dbh = $class->init_db;

    my $sql = ObjectDB::SQL->new(command => 'select',
                                 source  => $self->meta->table,
                                 columns => [$self->meta->columns],
                                 where   => [%{$self->to_hash}]);

    warn $sql if DEBUG;

    my $hash_ref = $dbh->selectrow_hashref("$sql");

    return unless keys %$hash_ref;

    $self->init(%$hash_ref);
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
    return $sth->execute(@values);
}

sub delete {
    my $class = shift;
    my $self = ref $class ? $class : $class->new();

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

        ObjectDB::Iterator->new(sth => $sth, class => $class);
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

        my $object;
        unless ($object = $relationship->{class}->find(@_)) {
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

        return $relationship->{class}->create(@params, @_);
    }
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

    my $objects =
        ref $_[0] eq 'ARRAY' ? $_[0] 
      : ref $_[0] eq 'HASH'  ? [$_[0]]
      :                        [{@_}];

    $self->delete_related($name);
    
    foreach my $object (@$objects) {
        $self->create_related($name, %$object);
    }

    return $self;
}

sub is_valid {
    my $self = shift;

    my $errors = 0;
    foreach my $col ($self->meta->columns) {
        my $options = $self->meta->_columns->{$col};

        $errors++ unless $self->_is_valid_null($col);

        if (%$options) {
            $errors++ unless $self->_is_valid_length($col);
            $errors++ unless $self->_is_valid_regex($col);
        }

        $errors++ unless $self->_is_valid_unique($col);
    }

    return $errors ? 0 : 1;
}

sub _is_valid_unique {
    my $self = shift;
    my $col = shift;

    return 1 unless $self->meta->is_unique_key($col);

    my $clone = $self->new($col => $self->column($col));
    return 1 unless $clone->find;

    my @primary_keys = $self->meta->primary_keys;

    foreach my $pk (@primary_keys) {
        if (!defined $self->column($pk)
            || !defined $clone->column($pk)
            || $self->column($pk) ne $clone->column($pk))
        {
            $self->error->{$col} ||= [];
            push @{$self->error->{$col}}, 'unique';

            return 0;
        }
    }

    return 1;
}

sub _is_valid_regex {
    my $self = shift;
    my $col  = shift;

    if (my $regex = $self->meta->_columns->{$col}->{regex}) {
        unless ($self->column($col) =~ qr/^$regex$/) {
            $self->error->{$col} ||= [];
            push @{$self->error->{$col}}, 'regex';
            return 0;
        }
    }

    return 1;
}

sub _is_valid_length {
    my $self = shift;
    my $col = shift;

    if (my $length = $self->meta->_columns->{$col}->{length}) {
        my $max_length;
        my $min_length;
        if (ref $length eq 'ARRAY') {
            $min_length = $length->[0];
            $max_length = $length->[1];
        } else {
            $min_length = 0;
            $max_length = $length;
        }

        return 1 if $min_length == 0 && not defined $self->column($col);

        if (   length $self->column($col) < $min_length
            || length $self->column($col) > $max_length)
        {
            $self->error->{$col} ||= [];
            push @{$self->error->{$col}}, 'length';

            return 0;
        }
    }

    return 1;
}

sub _is_valid_null {
    my $self = shift;
    my $col = shift;

    return 1 if $self->meta->is_auto_increment($col);

    return 1 if $self->meta->_columns->{$col}->{is_null};

    unless (defined $self->column($col) && $self->column($col) ne '') {
        $self->error->{$col} ||= [];
        push @{$self->error->{$col}}, 'null';
        return 0;
    }

    return 1;
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
