package ObjectDB::Relationship::Proxy;

use strict;
use warnings;

use base 'ObjectDB::Relationship::Base';

sub proxy_key { @_ > 1 ? $_[0]->{proxy_key} = $_[1] : $_[0]->{proxy_key} }

1;
__END__

=head1 NAME

ObjectDB::Relationship::Proxy - proxy relationship for ObjectDB

=head1 SYNOPSIS

    package Comment;

    use strict;
    use warnings;

    use base 'ObjectDB';

    __PACKAGE__->schema(
        table        => 'comment',
        columns      => [qw/master_id type content/],
        primary_keys => [qw/master_id type/],

        relationships => {
            master => {
                type      => 'proxy',
                proxy_key => 'type',
            },
            article => {
                type  => 'many to one',
                class => 'Article',
                map   => {master_id => 'id'}
            },
            podcast => {
                type  => 'many to one',
                class => 'Podcast',
                map   => {master_id => 'id'}
            }
        }
    );

    1;

=head1 DESCRIPTION

This is a proxy relationship. This way you can hold relationship name inside the
database. In example above calling $comment->related('master') returns master
object depending on $comment->column('type').

=head1 ATTRIBUTES

=head2 C<proxy_key>

Column name used for getting relationship name.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
