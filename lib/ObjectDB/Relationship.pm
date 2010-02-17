package ObjectDB::Relationship;

use strict;
use warnings;

sub build {
    my $class  = shift;
    my %params = @_;

    die 'type is required' unless $params{type};

    my @parts = map {ucfirst} split(' ', $params{type});
    my $rel_class = "ObjectDB::Relationship::" . join('', @parts);

    unless ($rel_class->can('isa')) {
        eval "require $rel_class";

        die "Error while loading $rel_class: $@" if $@;
    }

    return $rel_class->new(%params);
}

1;
__END__

=head1 NAME

ObjectDB::Relationship - Relationships for ObjectDB

=head1 SYNOPSIS

    my $rel = ObjectDB::Relationship->build(name => 'foo', type => 'many to one');

=head1 DESCRIPTION

    This is a relationship factory that is used internally.

=head1 METHODS

=head2 C<build>

Returns a new relationship instance. Could be one of
L<ObjectDB::Relationship::OneToOne>, L<ObjectDB::Relationship::OneToMany>,
L<ObjectDB::Relationship::ManyToOne>, L<ObjectDB::Relationship::ManyToMany>.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
