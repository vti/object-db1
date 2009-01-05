package ObjectDB::Relationship;

use strict;
use warnings;

use base 'ObjectDB::Base';

__PACKAGE__->attr([qw/ type _orig_class /]);

sub new {
    my $class = shift;
    my %params = @_;

    my $self =
      $class->SUPER::new(@_, _orig_class => delete $params{orig_class});
    
    return $self;
}

sub orig_class {
    my $self = shift;

    my $orig_class = $self->_orig_class;

    unless ($orig_class->can('isa')) {
        eval "require $orig_class;";
    }

    return $orig_class;
}

sub _load_relationship {
    my $self = shift;
    my ($object, $name) = @_;

    die "unknown relationship $name"
      unless $object->meta->relationships
          && exists $object->meta->relationships->{$name};

    my $relationship = $object->meta->relationships->{$name};

    if ($relationship->{type} eq 'proxy') {
        my $proxy_key = $relationship->{proxy_key};

        die "proxy_key is required for $name" unless $proxy_key;

        $name = $object->column($proxy_key);
        $relationship = $object->meta->relationships->{$name};
    }

    my $class;

    if ($relationship->{type} eq 'many to many') {
        $class = $relationship->{map_class};
        unless ($class->can('isa')) {
            eval "require $class;";
        }

        $relationship->{class} =
          $class->meta->relationships->{$relationship->{map_to}}->{class};
    }

    $class = $relationship->{class};

    unless ($class->can('isa')) {
        eval "require $class;";
    }

    return $relationship;
}

1;
