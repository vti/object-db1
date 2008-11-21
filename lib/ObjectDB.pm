package ObjectDB;

use strict;
use warnings;

use base 'ObjectDB::Base';

use DBI;
use ObjectDB::SQL;
use ObjectDB::Meta;

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

    my $sql = ObjectDB::SQL->new;

    $sql->command('insert')
      ->table($self->meta->table)
      ->columns([$self->meta->columns]);

    my @values = map { $self->column($_) } $self->meta->columns;

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
          unless $self->meta->is_primary_key($name);
    }

    my $dbh = $class->init_db;

    my $sql = ObjectDB::SQL->new;

    $sql->command('select')
      ->table($self->meta->table)
      ->columns(['*'])
      ->where(%params);

    warn $sql if DEBUG;

    my $hash_ref = $dbh->selectrow_hashref("$sql");

    return unless keys %$hash_ref;

    $self->init(%$hash_ref);

    return $self;
}

sub update {}

sub delete {
    my $class = shift;
    my $self = ref $class ? $class : $class->new();

    die 'query params are required' unless @_;

    my %params = @_;

    my @names = keys %params;

    foreach my $name (@names) {
        die "$name is not primary key or unique column"
          unless $self->meta->is_primary_key($name);
    }

    my $dbh = $class->init_db;

    my $sql = ObjectDB::SQL->new;

    $sql->command('delete')
      ->table($self->meta->table)
      ->where(%params);

    warn $sql if DEBUG;

    return $dbh->do("$sql");
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
