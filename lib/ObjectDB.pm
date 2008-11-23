package ObjectDB;

use strict;
use warnings;

use base 'ObjectDB::Base';

use DBI;
use ObjectDB::SQL;
use ObjectDB::Meta;
use ObjectDB::Iterator;

use constant DEBUG => $ENV{OBJECTDB_DEBUG} || 0;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    $self->init(@_);

    return $self;
}

sub init {
    my $self = shift;

    my %values = @_;
    foreach my $key ($self->meta->columns) {
        $self->column($key => $values{$key});
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

sub column {
    my $self = shift;

    $self->{_columns} ||= {};

    if (@_ == 1) {
        return $self->{_columns}->{$_[0]};
    } elsif (@_ == 2) {
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
                                 columns => [$self->meta->columns]);

    my @values = map { $self->column($_) } $self->meta->columns;

    warn $sql if DEBUG;

    my $sth = $dbh->prepare("$sql");
    my $rv = $sth->execute(@values);

    return unless $rv;
    
    if (my $auto_increment = $self->meta->auto_increment) {
        $self->column($auto_increment => $dbh->last_insert_id(undef, undef,
                $self->meta->table, $auto_increment));
    }

    return $self;
}

sub find {
    my $class = shift;
    my $self = ref $class ? $class : $class->new();
    my %params = @_;

    my @names = keys %params;

    foreach my $name (@names) {
        die "$name is not primary key or unique column"
          unless $self->meta->is_primary_key($name)
              || $self->meta->is_unique_key($name);
    }

    my $dbh = $class->init_db;

    my $sql = ObjectDB::SQL->new(command => 'select',
                                 source  => $self->meta->table,
                                 columns => [$self->meta->columns],
                                 where   => [%params]);

    warn $sql if DEBUG;

    my $hash_ref = $dbh->selectrow_hashref("$sql");

    return unless keys %$hash_ref;

    $self->init(%$hash_ref);

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
        return if $results eq '0E0';

        return $class->new(%{$results->[0]});
    } elsif (wantarray) {
        warn $sql if DEBUG;

        my $sth = $dbh->prepare("$sql");

        my $results = $dbh->selectall_arrayref("$sql", {Slice => {}});
        return () if $results eq '0E0';

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
                                 columns => ['COUNT(*) AS count'],
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

sub find_related {
    my $self = shift;
    my ($name) = shift;

    my $relationship = $self->_load_relationship($name);

    my %params = @_;

    #select * from tag join article_tag_map on tag.id=article_tag_map.tag_id where article_id=4;
    if ($relationship->{type} eq 'many to many') {
        my $map_from = $relationship->{map_from};
        my $map_to = $relationship->{map_to};

        my ($to, $from) =
          %{$relationship->{map_class}->meta->relationships->{$map_from}
              ->{map}};

        $params{where} ||= [];
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

        if ($relationship->{type} eq 'many to one') {
            $params{single} = 1;
        }

        $params{where} ||= [];
        push @{$params{where}}, ($to => $self->column($from));
    }

    return $relationship->{class}->find_objects(%params);
}

sub count_related {
    my $self = shift;
    my ($name) = shift;

    my $relationship = $self->_load_relationship($name);

    my %params = @_;

    my ($from, $to) = %{$relationship->{map}};

    my $where = delete $params{where} || [];

    return $relationship->{class}->count_objects(
        where => [$to => $self->column($from), @$where],
        @_
    );
}

sub update_related {
    my $self = shift;

    my ($name) = shift;

    my $relationship = $self->_load_relationship($name);

    my %params = @_;

    my ($from, $to) = %{$relationship->{map}};

    my $where = delete $params{where} || [];

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

    my ($from, $to) = %{$relationship->{map}};

    my $where = delete $params{where} || [];

    return $relationship->{class}->delete_objects(
        where => [$to => $self->column($from), @$where],
        @_
    );
}

sub to_hash {
    my $self = shift;

    my @columns = $self->meta->columns;

    my $hash = {};
    foreach my $key (@columns) {
        $hash->{$key} = $self->column($key);
    }

    return $hash;
}

1;
