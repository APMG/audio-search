package TQApp::Controller::V1::Media;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TQApp::Base::Controller::API' }

__PACKAGE__->config(
    model_name  => 'Media',
    primary_key => 'uuid',
);

# authz
around 'fetch' => sub {
    my ( $super_method, $self, $c, $uuid ) = @_;

    # user can only read own media
    # so fetch it, then verify owner.
    my $rt = $self->$super_method( $c, $uuid );
    if ( $c->stash->{user}->guid eq $c->stash->{object}->owner->guid ) {
        return $rt;
    }
    $c->log->debug("authz denied for /media/$uuid") if $c->debug;
    $self->status_forbidden( $c, message => 'Permission denied' );
    $c->stash( fetch_failed => 1 );    # trigger abort elsewhere
    return;
};

sub can_write {
    my ( $self, $c ) = @_;

    # user can only write if owner
    if ( $c->stash->{user}->guid eq $c->stash->{object}->owner->guid ) {
        return 1;
    }
    return 0;
}

# override GET /<uuid>/bar for some specific 'bar' values
around 'two_args_GET' => sub {
    my ( $super_method, $self, $c, $id, $rel ) = @_;
    return if $c->stash->{fetch_failed};

    if ( $self->can($rel) ) {
        $self->$rel($c);
    }
    else {
        $self->$super_method( $c, $id, $rel );
    }
};

sub text {
    my ( $self, $c ) = @_;
    my $media = $c->stash->{object};
    my $text  = $media->transcript_as_text;
    $self->status_ok( $c, entity => { text => $text, uuid => $media->uuid } );
}

sub keywords {
    my ( $self, $c ) = @_;
    my $media = $c->stash->{object};
    my $kw    = $media->keywords;
    $self->status_ok( $c,
        entity => { keywords => $kw, uuid => $media->uuid } );
}

1;
