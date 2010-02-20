package ObjectDB;

use strict;
use warnings;

use ObjectDB::SQL;
use ObjectDB::Schema;
require Carp;

use constant DEBUG => $ENV{OBJECTDB_DEBUG} || 0;

our $VERSION = '0.990103';

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->_related({});
    $self->_columns({});

    $self->init(@_);
    $self->is_in_db(0);
    $self->is_modified(0);

    return $self;
}

sub error { @_ > 1 ? $_[0]->{error} = $_[1] : $_[0]->{error} }

sub is_in_db { @_ > 1 ? $_[0]->{is_in_db} = $_[1] : $_[0]->{is_in_db} }

sub is_modified {
    @_ > 1 ? $_[0]->{is_modified} = $_[1] : $_[0]->{is_modified};
}

sub _related { @_ > 1 ? $_[0]->{_related} = $_[1] : $_[0]->{_related} }
sub _columns { @_ > 1 ? $_[0]->{_columns} = $_[1] : $_[0]->{_columns} }

sub init {
    my $self = shift;

    my %values = ref $_[0] ? %{$_[0]} : @_;
    foreach my $key ($self->schema->columns) {
        if (exists $values{$key}) {
            $self->column($key => $values{$key});
        }
        elsif (
            !defined $self->column($key)
            && defined(
                my $default = $self->schema->columns_map->{$key}->{default}
            )
          )
        {
            $self->_columns->{$key} = $default;
        }
    }

    if ($self->schema->relationships) {
        foreach my $rel (%{$self->schema->relationships}) {
            if (exists $values{$rel}) {
                $self->_related->{$rel} = delete $values{$rel};
            }
        }
    }

    # fake columns
    $self->_columns->{$_} = $values{$_} foreach (keys %values);

    return $self;
}

sub schema {
    my $class = shift;

    my $class_name = ref $class ? ref $class : $class;

    return $ObjectDB::Schema::objects{$class_name}
      ||= ObjectDB::Schema->new($class_name, @_);
}

sub columns {
    my $self = shift;

    my $columns = $self->_columns;

    my @columns;
    foreach my $key ($self->schema->columns) {
        if (exists $columns->{$key}) {
            push @columns, $key;
        }
        elsif (
            defined(
                my $default = $self->schema->columns_map->{$key}->{default}
            )
          )
        {
            $columns->{$key} = $default;
            push @columns, $key;
        }
    }

    return @columns;
}

sub column {
    my $self = shift;

    my $columns = $self->_columns;

    if (@_ == 1) {
        return defined $_[0] ? $columns->{$_[0]} : undef;
    }
    elsif (@_ == 2) {
        if (defined $columns->{$_[0]} && defined $_[1]) {
            $self->is_modified(1) if $columns->{$_[0]} ne $_[1];
        }
        elsif (defined $columns->{$_[0]} || defined $_[1]) {
            $self->is_modified(1);
        }

        $columns->{$_[0]} = $_[1];
    }

    return $self;
}

sub clone {
    my $self = shift;

    my %data;
    foreach my $column ($self->schema->columns) {
        next
          if $self->schema->is_primary_key($column)
              || $self->schema->is_unique_key($column);
        $data{$column} = $self->column($column);
    }

    return (ref $self)->new(%data);
}

sub _create_related {
    my $self = shift;

    my $relationships = $self->schema->relationships;

    if ($relationships) {
        foreach my $rel_name (keys %{$relationships}) {
            my $rel_type = $relationships->{$rel_name}->{type};

            if (my $rel_values = $self->_related->{$rel_name}) {
                if ($rel_type eq 'many to many') {
                    my $objects = $self->set_related($rel_name => $rel_values);
                    return unless $objects;

                    $self->related($rel_name => $objects);

                    return $self;
                }
                else {
                    my $data;

                    if (ref $rel_values eq 'ARRAY') {
                        $data = $rel_values;
                    }
                    elsif (ref $rel_values eq 'HASH') {
                        $data = [$rel_values];
                    }
                    elsif (ref $rel_values) {
                        $data = [$rel_values->to_hash];
                    }
                    else {
                        die
                          "wrong params when setting '$rel_name' relationship: $rel_values";
                    }

                    if ($rel_type eq 'one to many') {
                        my $objects = [];

                        foreach my $d (@$data) {
                            push @$objects,
                              $self->create_related($rel_name => $d);
                        }

                        $self->related($rel_name => $objects);
                    }
                    else {
                        my $rel_object = $self->create_related( $rel_name => $data->[0]);
                        $self->related( $rel_name => $rel_object);
                    }
                }
            }
        }
    }
    else {
        return;
    }
}

sub _update_related {
    my $self = shift;

    my $relationships = $self->schema->relationships;
    return $self unless $relationships;

    foreach my $rel_name (keys %$relationships) {
        if (my $rel = $self->_related->{$rel_name}) {
            my $type = $relationships->{$rel_name}->{type};

            foreach my $object (ref $rel eq 'ARRAY' ? @$rel : ($rel)) {
                $object->update;
            }
        }
    }

    return $self;
}

sub _delete_related {
    my $self = shift;

    my $relationships = $self->schema->relationships;
    return $self unless $relationships;

    my @rel_names = grep {
             $relationships->{$_}->{type} eq 'many to many'
          || $relationships->{$_}->{type} eq 'one to one'
          || $relationships->{$_}->{type} eq 'one to many'
    } (keys %{$relationships});

    foreach my $rel_name (@rel_names) {
        $self->delete_related($rel_name);
    }

    return $self;
}

sub begin_work {
    my $self = shift;

    return $self->init_db->begin_work;
}

sub rollback {
    my $self = shift;

    return $self->init_db->rollback;
}

sub commit {
    my $self = shift;

    return $self->init_db->commit;
}

sub create {
    my $self = shift;

    return $self if $self->is_in_db;

    my $dbh = $self->init_db;

    my $sql = ObjectDB::SQL->build('insert');
    $sql->table($self->schema->table);
    $sql->columns([$self->columns]);
    $sql->driver($dbh->{Driver}->{Name});
    $sql->to_string;

    my @values = map { $self->column($_) } $self->columns;

    warn "$sql" if DEBUG;

    my $sth = $dbh->prepare("$sql");
    unless ($sth) {
        $self->error($DBI::errstr);
        return;
    }

    my $rv  = $sth->execute(@values);
    unless ($rv && $rv eq '1') {
        $self->error($DBI::errstr);
        return;
    }

    if (my $auto_increment = $self->schema->auto_increment) {
        $self->column(
            $auto_increment => $dbh->last_insert_id(
                undef, undef, $self->schema->table, $auto_increment
            )
        );
    }

    $self->is_in_db(1);
    $self->is_modified(0);

    $self->_create_related;

    return $self;
}

sub load {
    my $self = shift;
    my %args = @_;

    my $dbh = $self->init_db;

    my @columns;
    foreach my $name ($self->columns) {
        push @columns, $name
          if $self->schema->is_primary_key($name)
              || $self->schema->is_unique_key($name);
    }

    Carp::croak "no primary or unique keys specified" unless @columns;

    my $sql = ObjectDB::SQL->build('select');

    $sql->source($self->schema->table);
    $sql->columns($self->schema->columns);
    $sql->where([map { $_ => $self->column($_) } @columns]);
    $sql->order_by();

    my $with;
    if ($with = delete $args{with}) {
        $with = [$with] unless ref $with eq 'ARRAY';
        $self->_resolve_with($sql, $with);
    }

    $sql->to_string;
    warn "$sql" if DEBUG;

    my $sth = $dbh->prepare("$sql");
    unless ($sth) {
        $self->error($DBI::errstr);
        return;
    }

    my $rv  = $sth->execute(@{$sql->bind});
    unless ($rv) {
        $self->error($DBI::errstr);
        return;
    }

    my $rows = $sth->fetchall_arrayref;
    return unless $rows && @$rows;

    my $object;
    foreach my $row (@$rows) {
        $object = $self->_map_row_to_object(
            row     => $row,
            columns => [$sql->columns],
            with    => $with,
            object  => $self,
            prev    => $object
        );
    }

    $object->is_in_db(1);
    $object->is_modified(0);

    return $self;
}

sub update {
    my $self = shift;
    my %args = @_;

    my $dbh = $self->init_db;

    my @columns;
    my @values;

    if (ref $self && !%args) {

        # If not modified update only related objects
        unless ($self->is_modified) {
            warn 'Not modified' if DEBUG;
            return $self->_update_related;
        }

        Carp::croak "no primary or unique keys specified" unless grep {
                  $self->schema->is_primary_key($_)
                    or $self->schema->is_unique_key($_)
        } $self->columns;

        $args{where} =
          [map { $_ => $self->column($_) } $self->schema->primary_keys];

        @columns =
          grep { !$self->schema->is_primary_key($_) } $self->columns;
        @values = map { $self->column($_) } @columns;

        die 'Object is empty, nothing to update' unless @columns && @values;
    }
    else {
        die 'set is required' unless $args{set};

        while (my ($key, $value) = each %{$args{set}}) {
            push @columns, $key;
            push @values,  $value;
        }
    }

    my $sql = ObjectDB::SQL->build('update');
    $sql->table($self->schema->table);
    $sql->columns(\@columns);
    $sql->bind(\@values);
    $sql->where([@{$args{where}}]) if $args{where};
    $sql->to_string;

    warn "$sql" if DEBUG;

    my $sth = $dbh->prepare("$sql");
    unless ($sth) {
        $self->error($DBI::errstr);
        return;
    }

    my $rv  = $sth->execute(@{$sql->bind});
    unless ($rv && $rv eq '1') {
        $self->error($DBI::errstr);
        return;
    }

    $self->_update_related if ref $self;

    return ref $self ? $self : $rv;
}

sub delete {
    my $self = shift;
    my %args = @_;

    my $dbh = $self->init_db;

    if (ref $self && !%args) {
        my @columns = $self->columns;

        my @keys = grep { $self->schema->is_primary_key($_) } @columns;
        unless (@keys) {
            @keys = grep { $self->schema->is_unique_key($_) } @columns;
        }

        Carp::croak "no primary or unique keys specified" unless @keys;

        $args{where} = [map { $_ => $self->column($_) } @keys];

        my $sql = ObjectDB::SQL->build('delete');
        $sql->table($self->schema->table);
        $sql->where([@{$args{where}}]) if $args{where};
        $sql->to_string;

        warn "$sql" if DEBUG;

        $self->_delete_related;

        my $sth = $dbh->prepare("$sql");
        unless ($sth) {
            $self->error($DBI::errstr);
            return;
        }

        my $rv  = $sth->execute(@{$sql->bind});
        unless ($rv && $rv eq '1') {
            $self->error($DBI::errstr);
            return;
        }

        return 1;
    }
    else {
        my %where = @{$args{where} || []};

        my $objects = $self->find(where => [%where]);
        return unless $objects && @$objects;

        my $count = 0;
        foreach my $object (@$objects) {
            return unless $object->delete;

            $count++;
        }

        return $count;
    }
}

sub find {
    my $class = shift;
    $class = ref($class) if ref($class);
    my %args = @_;

    my $dbh = $class->init_db;

    my $single = delete $args{single};

    my @columns;
    if (my $cols = delete $args{columns}) {
        @columns = ref $cols ? @$cols : ($cols);

        unshift @columns, $class->schema->primary_keys;
    }
    else {
        @columns = $class->schema->columns;
    }

    my $sql = ObjectDB::SQL->build('select');
    $sql->source($class->schema->table);
    $sql->columns(@columns);

    my $page = delete $args{page};
    my $page_size = delete $args{page_size} || 10;

    unless ($single) {
        if (defined $page) {
            $page = 1 unless $page && $page =~ m/^[0-9]+$/o;
            $sql->offset(($page - 1) * $page_size);
            $sql->limit($page_size);
        }
    }

    if (my $sources = delete $args{source}) {
        foreach my $source (@$sources) {
            $sql->source($source);
        }
    }

    my $with;
    if ($with = delete $args{with}) {
        $with = [$with] unless ref $with eq 'ARRAY';
        $class->_resolve_with($sql, $with);
    }

    $sql->merge(%args);

    $class->_resolve_columns($sql);
    $class->_resolve_order_by($sql);

    $sql->limit(1) if $single;
    $sql->to_string;

    warn "$sql" if DEBUG;

    my $sth = $dbh->prepare("$sql");
    unless ($sth) {
        #$self->error($DBI::errstr);
        return;
    }

    my $rv  = $sth->execute(@{$sql->bind});
    unless ($rv) {
        warn $DBI::errstr;
        #$self->error($DBI::errstr);
        return;
    }

    my $rows = $sth->fetchall_arrayref;
    return $single ? undef : [] unless $rows && @$rows;

    my $objects;
    my $prev;
    foreach my $row (@$rows) {
        my $object = $class->_map_row_to_object(
            row     => $row,
            columns => [$sql->columns],
            with    => $with,
            prev    => $prev
        );
        $object->is_in_db(1);
        $object->is_modified(0);

        push @$objects, $object if !$prev || $object ne $prev;

        $prev = $object;
    }

    return $single ? $objects->[0] : wantarray ? @$objects : $objects;
}

sub count {
    my $class = shift;
    my %args = @_;

    my $dbh = $class->init_db;

    my $table = $class->schema->table;
    my @pk = map {"`$table`.`$_`"} $class->schema->primary_keys;
    my $pk = join(',', @pk);

    my $sql = ObjectDB::SQL->build('select');
    $sql->source($class->schema->table);
    $sql->columns(\"COUNT(DISTINCT $pk)");
    $sql->to_string;

    if (my $sources = delete $args{source}) {
        $sql->source($_) foreach @$sources;
    }

    $sql->merge(%args);

    $class->_resolve_columns($sql);

    $sql->to_string;

    warn "$sql" if DEBUG;

    my $hash_ref = $dbh->selectrow_hashref("$sql", {}, @{$sql->bind});
    return unless $hash_ref && ref $hash_ref eq 'HASH';

    my @values = values %$hash_ref;
    return shift @values;
}

sub _load_relationship {
    my $self = shift;
    my ($name) = @_;

    die 'relationship name is required' unless $name;

    die "unknown relationship $name"
      unless $self->schema->relationships
          && exists $self->schema->relationships->{$name};

    my $relationship = $self->schema->relationships->{$name};

    if ($relationship->type eq 'proxy') {
        my $proxy_key = $relationship->proxy_key;

        die "proxy_key is required for $name" unless $proxy_key;

        $name = $self->column($proxy_key);

        die "proxy_key '$proxy_key' is empty" unless $name;

        $relationship = $self->schema->relationships->{$name};

        die "unknown relatioship $name" unless $relationship;
    }

    return $relationship;
}

sub create_related {
    my $self = shift;
    my ($name, $args) = @_;

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
        my $object =
          $self->find_related($name => {single => 1, where => [%$args]});

        # Already exists
        return $object if $object;

        my $map_from = $relationship->map_from;
        my $map_to   = $relationship->map_to;

        my ($from_foreign_pk, $from_pk) =
          %{$relationship->map_class->schema->relationships->{$map_from}
              ->{map}};

        my ($to_foreign_pk, $to_pk) =
          %{$relationship->map_class->schema->relationships->{$map_to}
              ->{map}};

        $object = $relationship->class->new(%$args)->load;

        if ($object) {
            return $relationship->map_class->new(
                $from_foreign_pk => $self->column($from_pk),
                $to_foreign_pk   => $object->column($to_pk)
            )->create;
        }
        else {
            $object = $relationship->class->new(%$args)->create;

            # Create map object
            $relationship->map_class->new(
                $from_foreign_pk => $self->column($from_pk),
                $to_foreign_pk   => $object->column($to_pk)
            )->create;

            return $object;
        }
    }
    else {
        my ($from, $to) = %{$relationship->map};

        my @params = ($to => $self->column($from));

        if ($relationship->where) {
            push @params, @{$relationship->where};
        }

        my $object = $relationship->class->new(@params, %$args);

        return $object->create;
    }
}

sub related {
    my $self = shift;
    my $name = shift;

    if ($_[0]) {
        $self->_related->{$name} = $_[0];
        return $self;
    }

    return $self->_related->{$name};
}

sub load_related {
    my $self = shift;
    my ($name, $args) = @_;

    my $objects = $self->find_related($name, $args);

    $self->related($name => $objects);

    return $objects;
}

sub find_related {
    my $self = shift;
    my ($name, $args) = @_;

    my $dbh = $self->init_db;

    my $relationship = $self->_load_relationship($name);

    $args->{where} ||= [];

    if ($relationship->{type} eq 'many to many') {
        my $map_from = $relationship->{map_from};
        my $map_to   = $relationship->{map_to};

        my ($to, $from) =
          %{$relationship->map_class->schema->relationships->{$map_from}
              ->{map}};

        push @{$args->{where}},
          (     $relationship->map_class->schema->table . '.'
              . $to => $self->column($from));

        $args->{source} =
          [$relationship->to_self_map_source, $relationship->to_self_source];
    }
    else {
        my ($from, $to) = %{$relationship->{map}};

        if (   $relationship->{type} eq 'many to one'
            || $relationship->{type} eq 'one to one')
        {
            $args->{single} = 1;

            return unless defined $self->column($from);
        }

        push @{$args->{where}}, ($to => $self->column($from));
    }

    if ($relationship->where) {
        push @{$args->{where}}, @{$relationship->where};
    }

    if ($relationship->with) {
        $args->{with} = $relationship->with;
    }

    $relationship->class->find(%$args);
}

sub count_related {
    my $self = shift;
    my ($name, $args) = @_;

    die 'at least the name of relationship is required' unless $name;

    my $dbh = $self->init_db;

    my $relationship = $self->_load_relationship($name);

    $args->{where} ||= [];

    if ($relationship->{type} eq 'many to many') {
        my $map_from = $relationship->{map_from};
        my $map_to   = $relationship->{map_to};

        my ($to, $from) =
          %{$relationship->map_class->schema->relationships->{$map_from}
              ->{map}};

        push @{$args->{where}},
          (     $relationship->map_class->schema->table . '.'
              . $to => $self->column($from));

        $args->{source} =
          [$relationship->to_self_map_source, $relationship->to_self_source];
    }
    else {
        my ($from, $to) = %{$relationship->map};

        push @{$args->{where}}, ($to => $self->column($from)),;
    }

    if ($relationship->where) {
        push @{$args->{where}}, @{$relationship->where};
    }

    return $relationship->class->count(%$args);
}

sub update_related {
    my $self = shift;
    my ($name, $args) = @_;

    my $relationship = $self->_load_relationship($name);

    if ($relationship->type eq 'many to many') {
        die 'many to many is not supported';
    }
    else {
        my ($from, $to) = %{$relationship->{map}};

        my $where = delete $args->{where} || [];

        if ($relationship->where) {
            push @{$args->{where}}, @{$relationship->where};
        }

        push @{$args->{where}}, ($to => $self->column($from));
    }

    return $relationship->class->update(%$args);
}

sub delete_related {
    my $self = shift;
    my ($name, $args) = @_;

    my $relationship = $self->_load_relationship($name);

    $args ||= {};
    $args->{where} ||= [];

    my $class_param = 'class';
    if ($relationship->{type} eq 'many to many') {
        my $map_from = $relationship->{map_from};
        my $map_to   = $relationship->{map_to};

        my ($to, $from) =
          %{$relationship->map_class->schema->relationships->{$map_from}
              ->{map}};

        push @{$args->{where}}, ($to => $self->column($from));

        $class_param = 'map_class';
    }
    else {
        my ($from, $to) = %{$relationship->{map}};

        push @{$args->{where}}, ($to => $self->column($from));
    }

    if ($relationship->where) {
        push @{$args->{where}}, @{$relationship->where};
    }

    return $relationship->$class_param->delete(%$args);
}

sub set_related {
    my $self = shift;
    my ($name, $args) = @_;

    my $dbh = $self->init_db;

    my $relationship = $self->_load_relationship($name);

    die "only 'many to many and one to one' are supported"
      unless $relationship->{type} eq 'many to many'
          || $relationship->{type} eq 'one to one';

    my @data;

    if (ref $args eq 'ARRAY') {
        @data = @$args;
    }
    elsif (ref $args eq 'HASH') {
        @data = ($args);
    }
    else {
        die 'wrong set_related params';
    }

    $self->delete_related($name);

    my $objects;
    foreach my $data (@data) {
        push @$objects, $self->create_related($name => $data);
    }

    return $relationship->{type} eq 'one to one' ? $objects->[0] : $objects;
}

sub _map_row_to_object {
    my $class = shift;
    $class = ref($class) if ref($class);
    my %params = @_;

    my $row     = $params{row};
    my $with    = $params{with};
    my $columns = $params{columns};
    my $o       = $params{object};
    my $prev    = $params{prev};

    my %values = map { $_ => shift @$row } @$columns;

    my $object = $o ? $o->init(%values) : $class->new(%values);

    if ($prev) {
        my $prev_keys = join(',',
            map { "$_=" . $prev->column($_) } $prev->schema->primary_keys);
        my $object_keys = join(',',
            map { "$_=" . $object->column($_) }
              $object->schema->primary_keys);

        if ($prev_keys eq $object_keys) {
            $object = $prev;
        }
    }

    if ($with) {
        foreach my $rel_info (@$with) {
            my $parent_object = $object;

            if ($rel_info->{subwith}) {
                foreach my $subwith (@{$rel_info->{subwith}}) {
                    $parent_object = $parent_object->_related->{$subwith};
                    die "load $subwith first" unless $parent_object;
                }
            }

            foreach my $parent_object_ (
                ref $parent_object eq 'ARRAY'
                ? @$parent_object
                : ($parent_object)
              )
            {
                my $relationship =
                  $parent_object_->schema->relationships->{$rel_info->{name}};

                %values = map { $_ => shift @$row } @{$rel_info->{columns}};

                if (grep { defined $values{$_} } keys %values) {
                    my $rel_object = $relationship->class->new(%values);

                    if (   $relationship->{type} eq 'many to one'
                        || $relationship->{type} eq 'one to one')
                    {
                        $parent_object_->_related->{$rel_info->{name}} =
                          $rel_object;
                    }
                    else {
                        $parent_object_->_related->{$rel_info->{name}} ||= [];
                        push
                          @{$parent_object_->_related->{$rel_info->{name}}},
                          $rel_object;
                    }
                }
            }
        }
    }

    return $object;
}

sub _resolve_with {
    my $class = shift;
    return unless @_;

    my ($sql, $with) = @_;

    foreach my $rel_info (@$with) {
        unless (ref $rel_info eq 'HASH') {
            $rel_info = {name => $rel_info};
        }

        my $relationship;
        my $relationships = $class->schema->relationships;
        my $last          = 0;
        my $name;
        my $rel_as;
        while (1) {
            if ($rel_info->{name} =~ s/^(\w+)\.//) {
                $name = $1;

                $rel_info->{subwith} ||= [];
                push @{$rel_info->{subwith}}, $name;
            }
            else {
                $name = $rel_info->{name};
                $last = 1;
            }

            unless ($relationship = $relationships->{$name}) {
                die $class . ": unknown relationship '$name'";
            }

            if ($relationship->type eq 'many to many') {
                $sql->source($relationship->to_map_source);
            }

            $sql->source($relationship->to_source(rel_as => $rel_as));

            if ($last) {
                my @columns;
                if ($rel_info->{columns}) {
                    $rel_info->{columns} = [$rel_info->{columns}]
                      unless ref $rel_info->{columns} eq 'ARRAY';

                    unshift @{$rel_info->{columns}},
                      $relationship->class->schema->primary_keys;
                }
                else {
                    $rel_info->{columns} =
                      [$relationship->class->schema->columns];
                }

                $sql->columns(@{$rel_info->{columns}});

                last;
            }
            else {
                $relationships = $relationship->class->schema->relationships;
            }

            $rel_as = $name;
        }
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
            }
            else {
                my $relationships = $self->schema->relationships;
                my $parent_prefix;
                while ($key =~ s/^(\w+)\.//) {
                    my $prefix = $1;

                    if (my $relationship = $relationships->{$prefix}) {
                        if ($relationship->type eq 'many to many') {
                            $sql->source($relationship->to_map_source);
                        }

                        $sql->source(
                            $relationship->to_source(
                                rel_as => $parent_prefix
                            )
                        );

                        my $rel_name = $relationship->name;
                        $where->[$count] = "$rel_name.$key";

                        $relationships =
                          $relationship->class->schema->relationships;

                        $parent_prefix = $prefix;
                    }
                }

                $count += 2;
            }
        }
    }

    return $self;
}

sub _resolve_order_by {
    my $self = shift;
    return unless @_;

    my ($sql) = @_;

    my $order_by = $sql->order_by;
    return unless $order_by;

    my @parts = split(',', $order_by);

    foreach my $part (@parts) {
        my $relationships = $self->schema->relationships;
        while ($part =~ s/^(\w+)\.//) {
            my $prefix = $1;

            if (my $relationship = $relationships->{$prefix}) {
                my $rel_table = $relationship->related_table;
                $part = "$rel_table.$part";

                $relationships = $relationship->class->schema->relationships;
            }
        }
    }

    $sql->order_by(join(', ', @parts));

    return $self;
}

sub to_hash {
    my $self = shift;

    my @columns = keys %{$self->{_columns}};

    my $hash = {};
    foreach my $key (@columns) {
        $hash->{$key} = $self->column($key);
    }

    foreach my $name (keys %{$self->_related}) {
        my $rel = $self->_related->{$name};

        die "unknown '$name' relationship" unless $rel;

        if (ref $rel eq 'ARRAY') {
        }
        elsif ($rel->isa('ObjectDB::Iterator')) {
        }
        else {
            $hash->{$name} = $rel->to_hash;
        }
    }

    return $hash;
}

1;
__END__

=head1 NAME

ObjectDB - Lightweight Object-relational mapper

=head1 SYNOPSIS

=head1 DESCRIPTION

ObjectDB is a lightweight, deps free (except L<DBI> of course) and flexible
object-relational mapper.

It combines all the best features from L<Class::DBI>, L<DBIx::Class> and
L<Rose::DB> but stays as light as possible.

L<ObjectDB> abstract is not that heavy as in L<Rose::DB>: columns are not
objects, everything is pretty much straight forward and flat.

Embedded SQL generator is similar to L<SQL::Abstract>, but leaves
low-level sql generation still possible.

=head1 ATTRIBUTES

=head2 is_in_db

Returns true when object was created or loaded. Otherwise false.

=head2 is_modified

Returns true when object was modified (setting columns). Otherwise false.

=head1 METHODS

=head2 C<new>

Returns a new L<ObjectDB> object.

=head2 C<init>

Sets objects columns.

=head2 C<schema>

Used to define class schema. For more information see L<ObjectDB::Schema>.

=head2 C<columns>

Returns object columns that are set or have a default value.

=head2 C<column>

Gets and sets column value.

=head2 C<clone>

Object cloning. Everything is copied except primary key and unique key values.

=head2 C<begin_work>

Begin transaction.

=head2 C<rollback>

Roll back transaction.

=head2 C<commit>

Commit transaction.

=head2 C<create>

Creates a new object. Sets auto increment field to the last inserted id.

=head2 C<load>

Loads object using primary key or unique key that was provided when creating a
new instance. Dies if there was no primary or unique key.

=head2 C<update>

Updates object.

=head2 C<delete>

Deletes object.

=head2 C<find>

Find objects. The second argument is a hashref that is translated into sql. Keys
that can be used:

=head3 C<where>

Build SQL. For more information see L<ObjectDB::SQL>.

=head3 C<with>

Prefetch related objects.

=head3 C<single>

By default C<find> returns array reference, by setting C<single> to 1 undef or
one object is returned (the first one).

=head3 C<order_by>

ORDER BY

=head3 C<having>

HAVING

=head3 C<limit>

LIMIT

=head3 C<offset>

OFFSET

=head3 C<page>

With C<page_size> you can select specific pages without calculation limit and
offset by yourself.

=head3 C<page_size>

The size of the C<page>. It is 20 items by default.

=head3 C<columns>

Select only specific columns.

=head2 C<count>

Count objects.

=head2 C<related>

    my $author = $article->related('author');

Gets prefetched related object(s).

=head2 C<create_related>

Creates related objects.

=head2 C<find_related>

Finds related objects.

=head2 C<load_related>

Same as C<find_objects> but sets C<related> method.

=head2 C<count_related>

Counts related objects.

=head2 C<update_related>

Updates related objects. Use set key for setting new values.

=head2 C<delete_related>

Deletes related objects.

=head2 C<set_related>

Creates and deletes related objects to satisfy the set. Usefull when setting
many to many relationships.

=head2 C<to_hash>

Serializes object to hash. All prefetched objects are serialized also.

=head1 SUPPORT

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/object-db/commits/master

=head1 SEE ALSO

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 CREDITS

In alphabetical order:

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
