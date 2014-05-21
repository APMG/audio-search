package TQApp::Model::Media;
use strict;
use base qw( TQApp::Base::Model::RDBO );
use MRO::Compat;
use mro 'c3';
use Data::Dump qw( dump );
use Carp;

__PACKAGE__->config(
    name      => 'TQ::Media',
    page_size => 50,
);

sub make_query {
    my $self = shift;
    my $q = $self->next::method(@_);

    # apply authz
    my $c = $self->context;
    my $user = $c->stash->{user} or confess "User required";
    push @{ $q->{query} }, ( user_id => $user->id );

    return $q;
}

1;
