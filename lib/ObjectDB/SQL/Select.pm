package ObjectDB::SQL::Select;

use strict;
use warnings;

use base 'ObjectDB::SQL::Base';

sub new {
    my $self = shift->SUPER::new(@_);

    $self->{_sources} ||= [];
    $self->{_columns} ||= [];

    return $self;
}

sub with     { @_ > 1 ? $_[0]->{with}     = $_[1] : $_[0]->{with} }
sub group_by { @_ > 1 ? $_[0]->{group_by} = $_[1] : $_[0]->{group_by} }
sub having   { @_ > 1 ? $_[0]->{having}   = $_[1] : $_[0]->{having} }
sub order_by { @_ > 1 ? $_[0]->{order_by} = $_[1] : $_[0]->{order_by} }
sub limit    { @_ > 1 ? $_[0]->{limit}    = $_[1] : $_[0]->{limit} }
sub offset   { @_ > 1 ? $_[0]->{offset}   = $_[1] : $_[0]->{offset} }
sub where    { @_ > 1 ? $_[0]->{where}    = $_[1] : $_[0]->{where} }

sub where_logic {
    @_ > 1 ? $_[0]->{where_logic} = $_[1] : $_[0]->{where_logic};
}

sub _sources { @_ > 1 ? $_[0]->{_sources} = $_[1] : $_[0]->{_sources} }
sub _columns { @_ > 1 ? $_[0]->{_columns} = $_[1] : $_[0]->{_columns} }


# Add sources, make sure that main source is loaded if schema class is available
sub source {
    my $self   = shift;
    my $source = shift;

    # Create main source if request comes from a schema class
    # and no source has been defined so far
    if ( $self->class && !@{$self->_sources} ){
        my $main_source = $self->class->schema->table;
        $self->_save_source($main_source);
    }

    # Save source that has been passed (if any)
    if ( defined $source && $source ne '' ){
        $self->_save_source($source);
    }

    # Return
    return $self;

}


# Save and validate source data
sub _save_source {
    my $self   = shift;
    my $source = shift;

    # Make source a hash ref
    $source = {name => $source} unless ref $source eq 'HASH';

    # Initialize key for columns
    $source->{columns} ||= [];

    # Alias: only add source when alias not in "_sources" as alias or name
    if (my $as = $source->{as}) {
        if ( !scalar( grep { $_->{name} eq $as } @{$self->_sources}) &&
             !scalar(
                grep { $_->{as} && ($_->{as} eq $as) } @{$self->_sources}
             ) 
        ){
            push @{$self->_sources}, $source;
        }
    }
    # No alias: only add source when name not in "_sources"
    elsif (!scalar(grep {$_->{name} eq $source->{name}} @{$self->_sources})){
        push @{$self->_sources}, $source;
    }

    # Return
    return $self;

}

sub columns {
    my $self = shift;

    ### Setter
    if (@_ && defined $_[0] && $_[0] ne '') {

        # Create main source if request comes from a schema class
        # and no source has been defined so far
        if ( $self->class && !@{$self->_sources} ){
            $self->source;
        }
        elsif ( !@{$self->_sources} ){
            die 'first define source';
        }

        # Save columns to last source
        $self->_sources->[-1]->{columns} =
          ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

        # Return
        return $self;

    }


    # Getter: return columns of main (first) source if no params passed
    my @column_names = ();

    return @column_names unless @{$self->_sources}; 

    foreach my $col (@{$self->_sources->[0]->{columns}}) {
        if (ref $col eq 'SCALAR') {
            $col = $$col;
        }
        elsif (ref $col eq 'HASH') {
            ($col) = $col->{as};
        }

        push @column_names, $col;
    }

    return @column_names;

}


sub to_string {
    my $self = shift;

    my $query = "";

    # Create main source if request comes from a schema class
    # and no source has been defined so far
    if ( $self->class && !@{$self->_sources} ){
        $self->source;
    }

    # Add columns for main source if not already added so far
    if ( $self->class && !@{$self->_sources->[0]->{columns}} ){
        $self->_sources->[0]->{columns} = [$self->class->schema->columns];
    }

    $query .= 'SELECT ';

    my $need_prefix = @{$self->_sources} > 1;
    my $first       = 1;
    foreach my $source (@{$self->_sources}) {
        if (@{$source->{columns}}) {
            $query .= ', ' unless $first;

            my @columns;
            foreach my $col (@{$source->{columns}}) {
                if (ref $col eq 'SCALAR') {
                    push @columns, $$col;
                }
                else {
                    my $col_full = $col;

                    my $as;
                    if (ref $col_full eq 'HASH') {
                        $as       = $col_full->{as};
                        $col_full = $col_full->{name};
                    }

                    if (ref $col_full eq 'SCALAR') {
                        $col_full = $$col_full;
                    }
                    else {
                        if ($col_full =~ s/^(\w+)\.//) {
                            $col_full = "`$1`.`$col_full`";
                        }
                        elsif ($need_prefix) {
                            $col_full = '`'
                              . ($source->{as} || $source->{name})
                              . "`.`$col_full`";
                        }
                        else {
                            $col_full = "`$col_full`";
                        }
                    }

                    push @columns, $as ? "$col_full AS $as" : $col_full;
                }
            }

            $query .= join(', ', @columns);

            $first = 0;
        }
    }

    $query .= ' FROM ';

    $query .= $self->_sources_to_string;

    my $default_prefix;
    if ($need_prefix) {
        $default_prefix = $self->_sources->[0]->{name};
    }

    if (my $where = $self->where) {
        if (ref $where eq 'ARRAY' && @$where || ref $where ne 'ARRAY') {
            $query .= ' WHERE ';
            $query .= $self->_where_to_string($self->where, $default_prefix);
        }
    }

    if (my $group_by = $self->group_by) {
        if ($default_prefix) {
            if ($group_by =~ s/^(\w+)\.//) {
                $group_by = "`$1`.`$group_by`";
            }
            else {
                $group_by = "`$default_prefix`.`$group_by`";
            }
        }
        else {
            $group_by = "`$group_by`";
        }

        $query .= ' GROUP BY ' . $group_by;
    }

    $query .= ' HAVING `' . $self->having . '`' if $self->having;

    if (my $order_by = $self->order_by) {
        my @cols = split(/\s*,\s*/, $order_by);

        $query .= ' ORDER BY ';

        my $first = 1;
        foreach my $col (@cols) {
            my $order;
            if ($col =~ s/\s+(ASC|DESC)\s*//i) {
                $order = $1;
            }

            if ($col =~ s/^(\w+)\.//) {
                $col = "`$1`.`$col`";
            }
            elsif ($default_prefix) {
                $col = "`$default_prefix`.`$col`";
            }
            else {
                $col = "`$col`";
            }

            $query .= ', ' unless $first;

            $query .= $col;
            $query .= ' ' . $order if $order;

            $first = 0;
        }
    }

    $query .= ' LIMIT ' . $self->limit if $self->limit;

    $query .= ' OFFSET ' . $self->offset if $self->offset;

    return $query;
}

sub _sources_to_string {
    my $self = shift;

    my $string = "";

    my $first = 1;
    foreach my $source (@{$self->_sources}) {
        $string .= ', ' unless $first || $source->{join};

        $string .= ' ' . uc $source->{join} . ' JOIN ' if $source->{join};

        $string .= '`' . $source->{name} . '`';

        if ($source->{as}) {
            $string .= ' AS ' . '`' . $source->{as} . '`';
        }

        if ($source->{constraint}) {
            $string .= ' ON ';

            my $count = 0;
            while (my ($key, $value) =
                @{$source->{constraint}}[$count, $count + 1])
            {
                last unless $key;

                $string .= ' AND ' unless $count == 0;

                my $from = $key;
                my $to   = $value;

                if ($from =~ s/^(\w+)\.//) {
                    $from = "`$1`.`$from`";
                }
                else {
                    $from = "`$from`";
                }

                if ($to =~ s/^(\w+)\.//) {
                    $to = "`$1`.`$to`";
                }
                else {
                    $to = "'$to'";
                }

                $string .= $from . ' = ' . $to;

                $count += 2;
            }
        }

        $first = 0;
    }

    return $string;
}

1;
__END__

=head1 NAME

ObjectDB::SQL::Select - SQL select for ObjectDB

=head1 SYNOPSIS

    This is used internally.

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 <where>

WHERE clause.

=head2 <where_logic>

WHERE clause logic (AND, OR).

=head2 <order_by>

ORDER BY

=head2 <limit>

LIMIT

=head2 <offset>

OFFSET

=head2 <group_by>

GROUP BY

=head2 <having>

HAVING

=head1 METHODS

=head2 C<source>

Used for joins.

=head2 C<columns>

Columns.

=head2 C<to_string>

String representation.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
