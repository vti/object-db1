package ObjectDB::Relationship::ManyToOne;

use strict;
use warnings;

use base 'ObjectDB::Relationship::Base';

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{map} ||= {};

    return $self;
}

sub map { @_ > 1 ? $_[0]->{map} = $_[1] : $_[0]->{map} }

sub to_source {
    my $self   = shift;
    my %params = @_;

    my $rel_as = $self->orig_class->schema->table;
    my $table = $self->class->schema->table;

    my ($from, $to) = %{$self->{map}};

    my $as = $self->name;

    my $constraint = ["$table.$to" => "$rel_as.$from"];

    if ($self->join_args) {
        my $i = 0;
        foreach my $value (@{$self->join_args}) {
            if ($i++ % 2) {
                push @$constraint, $value;
            }
            else {
                push @$constraint, "$table.$value";
            }
        }
    }

    return {
        name       => $table,
        as         => $table,
        join       => 'left',
        constraint => $constraint
    };
}

1;
__END__

=head1 NAME

ObjectDB::Relationship::ManyToOne - many to one relationship for ObjectDB

=head1 SYNOPSIS

    package Article;

    use strict;
    use warnings;

    use base 'ObjectDB';

    __PACKAGE__->schema(
        table          => 'article',
        columns        => [qw/ id author_id title /],
        primary_keys   => ['id'],
        auto_increment => 'id',

        relationships => {
            author => {
                type  => 'many to one',
                class => 'Author',
                map   => {author_id => 'id'}
            }
        }
    );

    1;

=head1 DESCRIPTION

Many to one relationship for L<ObjectDB>.

=head1 ATTRIBUTES

=head2 C<map>

Hash reference holding columns mappings.

=head1 METHODS

=head2 C<new>

Returns new L<ObjectDB::Relationship::ManyToOne> instance.

=head2 C<to_source>

Returns generated join arguments that are passed to the sql generator. Used
internally.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
