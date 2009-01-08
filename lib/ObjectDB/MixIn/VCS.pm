package ObjectDB::MixIn::VCS;

use strict;
use warnings;

use base 'ObjectDB::MixIn';

use Text::Diff();
use Text::Patch();

sub commit {
    my $class = shift;
    my $self = ref $class ? $class : $class->new(@_);

    unless ($self->is_in_db) {
        $self->column(addtime => time) unless $self->column('addtime');
        $self->column(revision => 1);
        $self->create();
        return $self;
    }

    return $self unless $self->is_modified;

    my $data = _diff($self);

    return $self unless defined $data;

    $self->create_related('diffs', %$data);

    $self->column(addtime => time) unless $self->column('addtime');
    $self->column(revision => $self->column('revision') + 1);
    $self->update();

    return $self;
}

sub load_revision {
    my $self = shift;
    my ($revision) = @_;

    return
      if !defined $revision
          || $self->column('revision') == $revision
          || $self->column('revision') < $revision
          || $revision <= 0;

    my @diffs = $self->find_related('diffs', order_by => 'revision DESC');

    my ($src_column, $diff_column);
    my $last_diff;
    foreach my $diff (@diffs) {
        foreach my $column (_versioned_columns($self)) {
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

        if ($diff->column('revision') == $revision) {
            $last_diff = $diff;
            last 
        }
    }

    foreach my $column (_not_versioned_columns($self)) {
        $self->column($column => $last_diff->column($column));
    }

    $self->column(revision => $revision);

    return $self;
}

sub rollback {
    my $self = shift;

    my $current_rev = $self->column('revision');

    return if $current_rev == 1;

    return unless $self->load_revision($current_rev - 1);
    $self->column(revision => $current_rev);
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
    foreach my $column (_versioned_columns($self)) {
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

    foreach my $column (_not_versioned_columns($self)) {
        $data->{$column} = $initial->column($column);
    }

    return $data;
}

sub _versioned_columns {
    my $self = shift;

    return grep {
            !$self->meta->is_primary_key($_)
          && $_ !~ m/(?:addtime|revision)/
          && !$self->meta->_columns->{$_}->{no_vcs}
    } $self->meta->relationships->{diffs}->class->meta->columns;
}

sub _not_versioned_columns {
    my $self = shift;

    return grep {
            !$self->meta->is_primary_key($_)
          && $_ !~ m/(?:addtime|revision)/
          && $self->meta->_columns->{$_}->{no_vcs}
    } $self->meta->relationships->{diffs}->{class}->meta->columns;
}

1;
