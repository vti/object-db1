package ObjectDB;

use strict;
use warnings;

use Digest::MD5 'md5_hex';
use ObjectDB::Chain::Count;
use ObjectDB::Chain::Delete;
use ObjectDB::Chain::Find;
use ObjectDB::SQL;
use ObjectDB::Schema;
use ObjectDB::Iterator;
require Carp;
require Encode;

use constant DEBUG => $ENV{OBJECTDB_DEBUG} || 0;

our $VERSION = '0.990201';

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

sub begin_work {
    my $self = shift;

    return $self->dbh->begin_work;
}

sub chained { @_ > 1 ? do {$_[0]->{chained} = $_[1]; return $_[0]} : $_[0]->{chained} }

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

sub columns {
    my $self = shift;

    my $columns = $self->_columns;

    if (@_) {
        !(@_ % 2) || die 'odd number of elements';
        my %key_value_pairs = @_;
        while (my ($key, $value) = each %key_value_pairs) {
            $self->column($key, $value);
        }
        return $self;
    }
    else {
        my @columns;
        foreach my $key ($self->schema->columns) {
            if (exists $columns->{$key}) {
                push @columns, $key;
            }
            elsif (
                defined(
                    my $default =
                      $self->schema->columns_map->{$key}->{default}
                )
              )
            {
                $columns->{$key} = $default;
                push @columns, $key;
            }
        }

        return @columns;

    }
}

sub commit {
    my $self = shift;

    return $self->dbh->commit;
}

sub count {
    my $self = shift;
    my %args  = @_;

    die '->count must be called on object instance' unless ref($self);

    my $chain = $self->_new_chain('count');
    return $chain if $self->chained;

    $chain->where($args{where}) if $args{where};
    return $chain->process;
}

sub count_related {
    my $self = shift;
    my ($name, $args) = @_;

    die 'at least the name of relationship is required' unless $name;

    my $relationship = $self->_load_relationship($name);

    $args ||= {};
    #$args->{where} ||= [];

    my $chain = $self->_new_chain('count', parent => $relationship->class->new);

    if ($relationship->{type} eq 'many to many') {
        my $map_from = $relationship->{map_from};
        my $map_to   = $relationship->{map_to};

        my ($to, $from) =
          %{$relationship->map_class->schema->relationships->{$map_from}
              ->{map}};

        $chain->where($relationship->map_class->schema->table . '.'
              . $to => $self->column($from));

        # Add sources manually, because they are not specified via the schema
        $chain->sql->source($relationship->to_self_map_source);
        $chain->sql->source($relationship->to_self_source);
    }
    else {
        my ($from, $to) = %{$relationship->map};

        $chain->where($to => $self->column($from));
    }

    #$chain->where($relationship->where) if $relationship->where;

    return $chain if $self->chained;

    #$chain->where($args->{where}) if $args->{where};

    return $chain->process;
}

sub create {
    my $self = shift;

    # Prevent creating again
    return $self if $self->is_in_db;

    my $dbh = $self->dbh;

    my $sql = ObjectDB::SQL->build('insert');
    $sql->table($self->schema->table);
    $sql->columns([$self->columns]);
    $sql->driver($dbh->{Driver}->{Name});

    my @values = map { $self->column($_) } $self->columns;

    my $sth = $dbh->prepare("$sql");
    unless ($sth) {
        $self->error($DBI::errstr);
        return;
    }

    my $rv = $sth->execute(@values);
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

sub create_related {
    my $self = shift;
    my ($name, $args) = @_;

    die '->create_related must be called on object instance' unless ref($self);

    $args = $args->to_hash unless ref $args eq 'HASH';

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

        $object = $relationship->class->new(%$args);
        $object->init_db($self->dbh);

        if ($object->load) {
            my $rel = $relationship->map_class->new(
                $from_foreign_pk => $self->column($from_pk),
                $to_foreign_pk   => $object->column($to_pk)
            );
            $rel->init_db($self->init_db);
            return $rel->create;
        }
        else {
            $object = $relationship->class->new(%$args);
            $object->init_db($self->dbh);
            $object->create;

            # Create map object
            my $rel = $relationship->map_class->new(
                $from_foreign_pk => $self->column($from_pk),
                $to_foreign_pk   => $object->column($to_pk)
            );
            $rel->init_db($self->init_db);
            $rel->create;

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
        $object->init_db($self->init_db);
        return $object->create;
    }
}

sub dbh {
    my $self = shift;

    return $self->init_db if $self->init_db;

    die '->init_db returned nothing';
}

sub delete {
    my $self = shift;
    my %args = @_;

    die '->delete must be called on object instance' unless ref($self);

    my $dbh = $self->dbh;

    # Delete object itself
    if (my @columns = $self->columns) {
        my $chain = $self->_new_chain('delete');

        my @columns = $self->columns;
        my @keys = grep { $self->schema->is_primary_key($_) } @columns;
        unless (@keys) {
            @keys = grep { $self->schema->is_unique_key($_) } @columns;
        }

        Carp::croak "->delete: no primary or unique keys specified"
          unless @keys;

        $chain->where(map { $_ => $self->column($_) } @keys);

        $self->_delete_related;

        return $chain->process;
    }

    my $chain = $self->_new_chain('find_and_delete');
    return $chain if $self->chained;

    $chain->where($args{where}) if $args{where};
    return $chain->process;
}

sub delete_related {
    my $self = shift;
    my ($name, $args) = @_;

    die '->delete_related must be called on object instance' unless ref($self);

    my $chain = $self->_new_chain('delete_related', name => $name);
    return $chain if $self->chained;

    $chain->where($args->{where}) if $args->{where};
    return $chain->process;
}

sub error { @_ > 1 ? $_[0]->{error} = $_[1] : $_[0]->{error} }

sub find {
    my $self = shift;
    my %args = @_;

    die '->find must be called on object instance' unless ref($self);

    my $chain = $self->_new_chain('find');
    return $chain if $self->chained;

    foreach my $method (
        qw/where with columns page page_size single iterator order_by limit/)
    {
        if (defined(my $value = $args{$method})) {
            $chain->$method($value);
        }
    }

    return $chain->process;
}

sub find_related {
    my $self = shift;
    my ($name, $args) = @_;

    my $relationship = $self->_load_relationship($name);

    $args ||= {};
    #$args->{where} ||= [];

    my $chain = $self->_new_chain('find', parent => $relationship->class->new);

    if ($relationship->{type} eq 'many to many') {
        my $map_from = $relationship->{map_from};
        my $map_to   = $relationship->{map_to};

        my ($to, $from) =
          %{$relationship->map_class->schema->relationships->{$map_from}
              ->{map}};

        $chain->where($relationship->map_class->schema->table . '.'
              . $to => $self->column($from));

        #push @{$args->{where}},
          #(     $relationship->map_class->schema->table . '.'
              #. $to => $self->column($from));

        #$args->{source} =
          #[$relationship->to_self_map_source, $relationship->to_self_source];

        $chain->sql->source($relationship->to_self_map_source);
        $chain->sql->source($relationship->to_self_source);
    }
    else {
        my ($from, $to) = %{$relationship->{map}};

        if (   $relationship->{type} eq 'many to one'
            || $relationship->{type} eq 'one to one')
        {
            $args->{single} = 1;

            return unless defined $self->column($from);
        }

        $chain->where($to => $self->column($from));
        #push @{$args->{where}}, ($to => $self->column($from));
    }

    if ($relationship->where) {
        $chain->where($relationship->where);
        #push @{$args->{where}}, @{$relationship->where};
    }

    if ($relationship->with) {
        #$args->{with} = $relationship->with;
        $chain->with($relationship->with);
    }

    return $chain if $self->chained;

    $chain->single(1) if $args->{single};
    $chain->where($args->{where}) if $args->{where};
    $chain->with($args->{with}) if $args->{with};

    return $chain->process;

    #my $rel = $relationship->class->new;
    #$rel->init_db($dbh);
    #return $rel->find(%$args);
}

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
        foreach my $rel (keys %{$self->schema->relationships}) {
            if (exists $values{$rel}) {
                my $rel_values = delete $values{$rel};

                my $rel_class = $self->schema->relationships->{$rel}->class;

                if (ref $rel_values eq 'ARRAY') {
                    $self->_related->{$rel} ||= [];
                    foreach my $rel_value (@$rel_values) {
                        my $object = $rel_class->new(%$rel_value);
                        $object->init_db($self->init_db);
                        push @{$self->_related->{$rel}}, $object;
                    }
                }
                else {
                    my $object = $rel_class->new(%$rel_values);
                    $object->init_db($self->init_db);
                    $self->_related->{$rel} = $object;
                }
            }
        }
    }

    # fake columns
    $self->_columns->{$_} = $values{$_} foreach (keys %values);

    return $self;
}

sub init_db {
    my $self = shift;

    return $self->{init_db} unless @_;

    $self->{init_db} = $_[0];
}

sub is_modified {
    @_ > 1 ? $_[0]->{is_modified} = $_[1] : $_[0]->{is_modified};
}

sub is_in_db { @_ > 1 ? $_[0]->{is_in_db} = $_[1] : $_[0]->{is_in_db} }

sub load {
    my $self = shift;
    my %args = @_;

    my $dbh = $self->dbh;

    my $chain = $self->_new_chain('load');

    return $chain if $self->chained;

    $chain->with($args{with}) if $args{with};

    return $chain->process;
}

sub load_related {
    my $self = shift;
    my ($name, $args) = @_;

    my $objects = $self->find_related($name, $args);

    $self->related($name => $objects);

    return $objects;
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

sub rollback {
    my $self = shift;

    return $self->dbh->rollback;
}

sub schema {
    my $class = shift;

    my $class_name = ref $class ? ref $class : $class;

    return $ObjectDB::Schema::objects{$class_name}
      ||= ObjectDB::Schema->new($class_name, @_);
}

sub set_related {
    my $self = shift;
    my ($name, $args) = @_;

    my $relationship = $self->_load_relationship($name);

    die "only 'many to many and one to one' are supported"
      unless $relationship->{type} eq 'many to many'
          || $relationship->{type} eq 'one to one';

    my @data;

    if (ref $args eq 'ARRAY') {
        @data = map { ref $_ eq 'HASH' ? $_ : $_->to_hash } @$args;
    }
    elsif (ref $args eq 'HASH') {
        @data = ($args);
    }
    elsif (ref $args) {
        @data = ($args->to_hash);
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

sub sign {
    my $self = shift;

    my @values = map { $_ => $self->column($_) || '' } $self->columns;

    foreach (@values) {
        $_ = Encode::encode_utf8($_) if Encode::is_utf8($_);
    }

    my $class = ref($self);
    return md5_hex($class . ':' . join(',', @values));
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
            $hash->{$name} = [];
            foreach my $r (@$rel) {
                push @{$hash->{$name}}, $r->to_hash;
            }
        }
        else {
            $hash->{$name} = $rel->to_hash;
        }
    }

    return $hash;
}

sub update {
    my $self = shift;
    my %args = @_;

    my $dbh = $self->dbh;

    my @columns;
    my @values;

    if (!%args) {
        Carp::croak "->update: no primary or unique keys specified"
          unless grep {
                 $self->schema->is_primary_key($_)
              or $self->schema->is_unique_key($_)
          } $self->columns;

        # If not modified update only related objects
        unless ($self->is_modified) {
            warn 'Not modified' if DEBUG;
            return $self->_update_related;
        }

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

    warn "$sql" if $ENV{OBJECTDB_DEBUG};

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

    $self->_update_related if ref $self;

    return $self;
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

    my $rel = $relationship->class->new;
    $rel->init_db($self->init_db);
    return $rel->update(%$args);
}

sub _columns { @_ > 1 ? $_[0]->{_columns} = $_[1] : $_[0]->{_columns} }

sub _create_related {
    my $self = shift;

    my $relationships = $self->schema->relationships;

    # Nothing to do
    return unless $relationships;

    foreach my $rel_name (keys %{$relationships}) {
        my $rel_type = $relationships->{$rel_name}->{type};

        if (my $rel_values = $self->_related->{$rel_name}) {
            if ($rel_type eq 'many to many') {
                my $objects =
                  $self->set_related($rel_name => $rel_values);
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
                    my $rel_object =
                      $self->create_related($rel_name => $data->[0]);
                    $self->related($rel_name => $rel_object);
                }
            }
        }
    }
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

sub _map_rows_to_objects {
    my $self = shift;
    my $class = ref($self);
    my %params = @_;

    my $rows    = $params{rows};
    my $sql     = $params{sql};
    my $with    = $sql->with if $sql;
    my $columns = [$sql->columns] if $sql;

    my $map     = {};
    my $objects = [];

    foreach my $row (@$rows) {
        my @col;
        foreach my $col (@$columns) {
            push @col, $col => shift @$row;
        }

        my $object = $class->new(@col);
        $object->init_db($self->dbh);
        $object->is_in_db(1);
        $object->is_modified(0);

        my $sign = $object->sign;

        if (exists $map->{$sign}) {
            $object = $map->{$sign};
        }
        else {
            $map->{$sign} = $object;
            push @$objects, $object;
        }

        next unless $with;

        my $parent_object  = $object;
        my @recent_parents = ($object);
        foreach my $rel_info (@$with) {
            if ($rel_info->{subwith}) {
                foreach my $recent_parent (@recent_parents) {
                    $parent_object =
                      $recent_parent->_related->{$rel_info->{subwith}};
                    last if $parent_object;
                }

                unless ($parent_object) {
                    map { $_ => shift @$row } @{$rel_info->{columns}};
                    next;
                }
            }

            # Parent object can be array ref if !$rel_info->{subwith}
            $parent_object = $parent_object->[-1]
              if ref $parent_object eq 'ARRAY';

            my @values = map { $_ => shift @$row } @{$rel_info->{columns}};

            my %values = @values;
            next unless grep {defined} values %values;

            my $relationship =
              $parent_object->schema->relationships->{$rel_info->{name}};

            my $rel_object = $relationship->class->new(@values);

            $rel_object->init_db($self->dbh);
            $rel_object->is_in_db(1);
            $rel_object->is_modified(0);

            my $sign = $rel_info->{name} . $rel_object->sign;

            if ($map->{$sign}) {
                unshift(@recent_parents, $map->{$sign});
                next;
            }

            unshift(@recent_parents, $rel_object);

            $map->{$sign} = $rel_object;

            if (   $relationship->{type} eq 'many to one'
                || $relationship->{type} eq 'one to one')
            {
                $parent_object->_related->{$rel_info->{name}} = $rel_object;
            }
            else {
                $parent_object->_related->{$rel_info->{name}} ||= [];
                push
                  @{$parent_object->_related->{$rel_info->{name}}},
                  $rel_object;
            }
        }
    }

    return $objects;
}

sub _new_chain {
    my $self = shift;
    my $name = shift;

    # Decamelize
    $name = join '' => map {ucfirst} split '_' => $name;

    my $class = "ObjectDB::Chain::$name";

    # Already loaded
    unless ($class->can('new')) {
        eval "require $class";
        die $@ if $@;
    }

    my $chain = $class->new(parent => $self, @_);
    $chain->init_db($self->dbh);
    return $chain;
}

sub _related { @_ > 1 ? $_[0]->{_related} = $_[1] : $_[0]->{_related} }

sub _update_related {
    my $self = shift;

    my $relationships = $self->schema->relationships;
    return $self unless $relationships;

    foreach my $rel_name (keys %$relationships) {
        if (my $rel = $self->_related->{$rel_name}) {
            my $type = $relationships->{$rel_name}->{type};

            foreach my $object (ref $rel eq 'ARRAY' ? @$rel : ($rel)) {
                $object->init_db($self->init_db);
                $object->update;
            }
        }
    }

    return $self;
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

Begin transchain.

=head2 C<rollback>

Roll back transchain.

=head2 C<commit>

Commit transchain.

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

Andre Vieth

Mirko Westermeier

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
