package ObjectDB::SQL;

use strict;
use warnings;

sub build {
    my $class   = shift;
    my $command = shift;

    die 'command is required' unless $command;

    my $command_class = 'ObjectDB::SQL::' . ucfirst $command;

    unless ($command_class->can('isa')) {
        eval "require $command_class";

        die "Error while loading $command_class: $@" if $@;
    }

    return $command_class->new(@_);
}

1;
__END__

=head1 NAME

ObjectDB::SQL - SQL factory for ObjectDB

=head1 SYNOPSIS

    my $sql = ObjectDB::SQL->build('select');

    $sql = ObjectDB::SQL->build('insert');
    $sql->table('foo');
    $sql->columns([qw/a b c/]);
    $sql->bind([qw/a b c/]);

=head1 DESCRIPTION

This an SQL factory for L<ObjectDB>.

=head1 METHODS

=head2 C<build>

Returns a new instance of L<ObjectDB::SQL::Select>, L<ObjectDB::SQL::Insert>,
L<ObjectDB::SQL::Update> or L<ObjectDB::SQL::Delete>.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
