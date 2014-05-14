package TQApp::Controller::V1::Media;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TQApp::Base::Controller::API' }

__PACKAGE__->config(
    model_name  => 'Media',
    primary_key => 'uuid',
);

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
