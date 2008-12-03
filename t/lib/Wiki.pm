package Wiki;

use strict;
use warnings;

use base 'DB';

use Text::Diff();
use Text::Patch();

__PACKAGE__->meta(
    table          => 'wiki',
    columns        => [qw/ id title addtime revision /],
    primary_keys   => ['id'],
    auto_increment => 'id',

    relationships => {
        diffs => {
            type  => 'one to many',
            class => 'WikiDiff',
            map   => {id => 'wiki_id'}
        }
    }
);

sub commit {
    my $self = shift;

    unless ($self->is_in_db) {
        $self->column(addtime => time) unless $self->column('addtime');
        $self->column(revision => 1);
        $self->create();
        return;
    }

    return unless $self->is_modified;

    my $data = _diff($self);

    return unless defined $data;

    $self->create_related('diffs', %$data);

    $self->column(addtime => time) unless $self->column('addtime');
    $self->column(revision => $self->column('revision') + 1);
    $self->update();
}

sub find_revision {
    my $self = shift;
    my ($revision) = @_;

    return
      if !defined $revision
          || $self->column('revision') == $revision
          || $self->column('revision') < $revision
          || $revision <= 0;

    my @diffs = $self->find_related('diffs', order_by => 'revision DESC');

    my ($src_column, $diff_column);
    foreach my $diff (@diffs) {
        foreach my $column ($self->_versioned_columns) {
            $src_column  = $self->column($column);
            $diff_column = $diff->column($column);

            if ($src_column && $diff_column) {
                my $val =
                  Text::Patch::patch($src_column, $diff_column,
                    {STYLE => 'Unified'});
                $val =~ s/\n$//;
                $self->column($column => $val);
            }
            else {
                $self->column($column => $src_column);
            }
        }

        last if $diff->column('revision') == $revision;
    }

    return $self;
}

sub rollback {
    my $self = shift;

    my $current_rev = $self->column('revision');

    return if $current_rev == 1;

    $self->find_revision($current_rev - 1);
    $self->commit;
}

sub _diff {
    my $self = shift;

    my @pk = $self->meta->primary_keys;
    my @pk_values = map { $self->column($_) } @pk;

    my $initial = $self->meta->class->select(@pk_values);
    return unless $initial;

    my $data = {
        addtime  => $initial->column('addtime'),
        revision => $initial->column('revision')
    };

    my $has_changed_columns = 0;
    my ($new, $old);
    foreach my $column ($self->_versioned_columns) {
        $new = $self->column($column) || '';
        $new .= "\n";

        $old = $initial->column($column) || '';
        $old .= "\n";

        $data->{$column} =
          Text::Diff::diff(\$new, \$old, {STYLE => 'Unified'});

        if ($data->{$column}) {
            $has_changed_columns++;
        } else {
            delete $data->{$column};
        }
    }

    return unless $has_changed_columns;

    return $data;
}

sub _versioned_columns {
    my $self = shift;

    return
      grep { !$self->meta->is_primary_key($_) && $_ !~ m/(?:addtime|revision)/ }
      $self->meta->relationships->{diffs}->{class}->meta->columns;
}

1;
