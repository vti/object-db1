package ObjectDB::Relationship::OneToOne;

use strict;
use warnings;

use base 'ObjectDB::Relationship::ManyToOne';

1;
__END__

=head1 NAME

ObjectDB::Relationship::OneToOne - one to one relationship for ObjectDB

=head1 SYNOPSIS

    package Author;

    use strict;
    use warnings;

    use base 'ObjectDB';

    __PACKAGE__->schema(
        table          => 'author',
        columns        => [qw/id name password/],
        primary_keys   => ['id'],
        auto_increment => 'id',
        unique_keys    => 'name',

        relationships => {
            author_admin => {
                type  => 'one to one',
                class => 'AuthorAdmin',
                map   => {id => 'author_id'}
            }
        }
    );

    1;

=head1 DESCRIPTION

One to one relationship for L<ObjectDB>.

=head1 ATTRIBUTES

Inherits everything from L<ObjectDB::Relationship::ManyToOne>.

=head1 METHODS

Inherits everything from L<ObjectDB::Relationship::ManyToOne>.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
