package ObjectDB::RelationshipFactory;

use strict;
use warnings;

sub build {
    my $class = shift;
    my %params = @_;

    die 'type is required' unless $params{type};

    my @parts = map {ucfirst} split(' ', $params{type});
    my $rel_class = "ObjectDB::Relationship::" . join('', @parts);

    unless ($rel_class->can('isa')) {
        eval "require $rel_class;";
    }

    return $rel_class->new(%params);
}


1;
