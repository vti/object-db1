package ObjectDB::Relationship::OneToMany;

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
    my $self = shift;

    my $table     = $self->orig_class->schema->table;
    my $rel_table = $self->class->schema->table;

    my ($from, $to) = %{$self->map};

    my $as;
    if ( $table eq $rel_table ){
        $as = $self->name;
    }
    else {
        $as = $rel_table;
    }


    my @args = ();
    if ($self->{where}) {
        for (my $i = 0; $i < @{$self->{where}}; $i += 2) {
            push @args,
              $as . '.' . $self->{where}->[$i] => $self->{where}->[$i + 1];
        }
    }

    return {
        name       => $rel_table,
        join       => 'left',
        as         => $as,
        constraint => ["$as.$to" => "$table.$from", @args]
    };
}

1;
__END__

=head1 NAME

ObjectDB::Relationship::OneToMany - one to many relationship for ObjectDB

=head1 SYNOPSIS

    package Article;

    use strict;
    use warnings;

    use base 'ObjectDB';

    __PACKAGE__->schema(
        table          => 'article',
        columns        => [qw/ id category_id author_id title /],
        primary_keys   => ['id'],
        auto_increment => 'id',

        relationships => {
            comments => {
                type  => 'one to many',
                class => 'Comment',
                map   => {id => 'comment_id'}
            }
        }
    );

    1;

=head1 DESCRIPTION

One to many relationship for L<ObjectDB>.

=head1 ATTRIBUTES

=head2 C<map>

Hash reference holding columns mappings.

=head1 METHODS

=head2 C<new>

Returns new L<ObjectDB::Relationship::OneToMany> instance.

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
