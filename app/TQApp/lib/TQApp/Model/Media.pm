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

# can't use config.load_with in combination with 'select'
# feature so just load manually.
my @load_with = qw( jobs owner );

#$ENV{CATALYST_DEBUG} = 2;    # trigger rdbo debug

sub fetch {
    my $self  = shift;
    my $media = $self->next::method(@_);
    $media->$_ for @load_with;
    return $media;
}

sub make_query {
    my $self = shift;
    my $q    = $self->next::method(@_);

    # apply authz
    my $c = $self->context;
    my $user = $c->stash->{user} or confess "User required";
    push @{ $q->{query} }, ( user_id => $user->id );

    return $q;
}

sub search {
    my $self = shift;
    my (@arg) = @_;
    if ( $arg[0] and ref $arg[0] eq 'HASH' ) {
        my $c = $self->context;

        # trim results if asked
        # cxc-minimal to avoid pulling transcript when not needed (list view)
        # NOTE need id and user_id for @load_with
        if ( $c->req->params->{'cxc-minimal'} ) {
            $arg[0]->{select}
                = [qw( uuid name updated_at status uri duration id user_id )];
        }
        if ( $c->req->params->{'cxc-select'} ) {
            $arg[0]->{select} = $c->req->params->{'cxc-select'};
        }
    }

    my $objs = $self->next::method(@arg);
    for my $m (@$objs) {
        $m->$_ for @load_with;
    }
    return wantarray ? @$objs : $objs;
}

1;
