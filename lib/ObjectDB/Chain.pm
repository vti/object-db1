package ObjectDB::Chain;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub error { shift->parent->error(@_) }

sub init_db { @_ > 1 ? $_[0]->{init_db} = $_[1] : $_[0]->{init_db} }
sub parent  { @_ > 1 ? $_[0]->{parent}  = $_[1] : $_[0]->{parent} }
sub sql     { shift->{sql} }

sub _resolve_columns {
    my $self  = shift;
    my $where = @_ > 1 ? [@_] : $_[0];

    return unless @$where;

    my $class = ref($self->parent);

    my $count = 0;
    while (my ($key, $value) = @{$where}[$count, $count + 1]) {
        last unless $key;

        if (ref $key eq 'SCALAR') {
            $count++;
        }
        else {
            my $relationships = $class->schema->relationships;
            while ($key =~ s/^(\w+)\.//) {
                my $prefix = $1;

                if (my $relationship = $relationships->{$prefix}) {
                    if ($relationship->type eq 'many to many') {
                        $self->sql->source($relationship->to_map_source);
                    }

                    $self->sql->source($relationship->to_source);

                    my $rel_name = $relationship->class->schema->table;
                    $where->[$count] = "$rel_name.$key";

                    $relationships =
                      $relationship->class->schema->relationships;
                }
            }

            $count += 2;
        }
    }

    return $where;
}

sub _resolve_with {
    my $self = shift;

    return unless @_;
    my $with = @_ > 1 ? [@_] : ref($_[0]) eq 'ARRAY' ? $_[0] : [$_[0]];

    # Nothing to resolve
    return unless @$with;

    my $relationships = $self->parent->schema->relationships;

    my @new_rel_info;
    foreach my $rel_info (@$with) {

        # Normalize
        unless (ref $rel_info eq 'HASH') {
            $rel_info = {name => $rel_info};
        }

        my $relationship;
        my $last          = 0;
        my $name;
        my $last_rel;
        while (1) {
            if ($rel_info->{name} =~ s/^(\w+)\.//) {
                $name = $1;

                $rel_info->{subwith} = $name;
            }
            else {
                $name = $rel_info->{name};
                $last = 1;
            }

            unless ($relationship = $relationships->{$name}) {
                die "unknown relationship '$name'";
            }

            if ($relationship->type eq 'many to many') {
                $self->sql->source($relationship->to_map_source);
            }

            my $success = $self->sql->source($relationship->to_source);

            if ($last && $success) {
                my @columns;
                if ($rel_info->{columns}) {
                    $rel_info->{columns} = [$rel_info->{columns}]
                      unless ref $rel_info->{columns} eq 'ARRAY';

                    unshift @{$rel_info->{columns}},
                      $relationship->class->schema->primary_keys;
                }
                else {
                    $rel_info->{columns} =
                      [$relationship->class->schema->columns];
                }

                $self->sql->columns(@{$rel_info->{columns}});

                last;
            }
            elsif ($last && !$success) {
                last;
            }
            elsif ($success) {
                my $new_sub_with = $last_rel if $last_rel;
                my $new_rel_info = {
                    name    => $name,
                    subwith => $new_sub_with,
                    columns => [$relationship->class->schema->columns]
                };

                unshift @new_rel_info, $new_rel_info if $success;

                $self->sql->columns($relationship->class->schema->columns)
                  if $success;

            }

            $relationships = $relationship->class->schema->relationships;

            $last_rel = $name;
        }
    }

    #foreach my $new_rel_info (@new_rel_info) {
        #unshift @$with, $new_rel_info;
    #}

    return $with;
}

1;
