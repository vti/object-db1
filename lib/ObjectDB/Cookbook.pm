package ObjectDB::Cookbook;

1;
__END__

=head1 NAME

ObjectDB::Cookbook - Cooking with ObjectDB

=head1 RECIPIES

=head2 Single object manipulations

=head3 Create

    # Create new article with title 'foo'
    my $article = Article->new(title => 'foo');
    $article->create;

=head3 Update

    # Update loaded article
    $article->column(title => 'bar');
    $article->update;

=head3 Delete

    # Delete loaded article
    $article->delete;

=head3 Load

    # Load article providing a primary key 'id'
    my $article = Article->new(id => 1);
    $article->load;

=head2 Multiple objects manipulations

Find

    # Find articles with title 'foo'
    my $articles = Article->find(where => [title => 'foo']);

    # Find article with title 'foo'
    my $articles = Article->find(where => [title => 'foo'], single => 1);

    # Find articles using paging
    my $articles = Article->find(page => 1, page_size => 10);

Update

    # Update articles titles to 'bar' where titles are 'foo'
    Author->update(set => {title => 'bar'}, where => [title => 'foo']);

Delete

    # Delete all articles
    Article->delete;

    # Delete articles where title is 'foo'
    Article->delete(where => [title => 'foo']);

Count

    # Count all articles
    my $total = Article->count;

    # Count articles where title is 'foo'
    my $total_with_title_foo = Article->count(where => [title => 'foo']);

=head2 Relationships

Manipulations on related objects

    $article->find_related('comments', where => [author => 'foo']);
    $article->delete_related('comments', where => [author => 'foo']);
    $article->count_related('comments', where => [author => 'foo']);
    $article->update_related(
        'comments',
        set   => {author => 'bar'},
        where => [author => 'foo']
    );
    $article->set_related('tags' => {name => 'foo'});

Preloading related objects

    my $article = Article->find(with => 'tags');

Preloading related objects on demand

    my $tags = $article->load_related('tags');

Accessing preloaded related objects

    my $tags = $article->related('tags');

Deep nested relationships

    # Find author whose articles are in 'foo' category
    my $authors = Author->find(where => ['articles.category.title' => 'foo']);

=head2 Real world examples

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
