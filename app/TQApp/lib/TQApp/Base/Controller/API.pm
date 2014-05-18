package TQApp::Base::Controller::API;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::CRUD::Controller::REST' }

use Try::Tiny;

__PACKAGE__->config(
    default                => 'application/json',
    content_type_stash_key => 'mime_type',
    page_size              => 50,
);

sub auto : Private {
    my ( $self, $c ) = @_;

    my $api_key = $c->req->params->{tq};

    if ( !$api_key ) {
        $c->res->header( 'X-TQ' => 'missing tq API key' );
        $self->status_forbidden( $c, message => 'Permission denied' );
        return 0;
    }

    # find and stash the user
    my $user = try {
        $c->model('User')->fetch( api_key => $api_key );
    }
    catch {
        $c->res->header( 'X-TQ' => 'invalid API key' );
        $self->status_forbidden( $c, message => 'Permission denied' );
        return 0;
    } or return 0;

    $c->log->debug( 'valid api request for ' . $user->email );
    $c->stash( user => $user );
    return 1;
}

# determine response type from URL file extension
# the _ext_to_type method is from the Static::Simple Plugin
around fetch => sub {
    my $orig = shift;
    my ( $self, $c, $id ) = @_;
    my $mime = $c->_ext_to_type($id);
    $mime =~ s,application/xml,text/xml,g;
    $c->stash( mime_type => $mime );
    $c->log->debug( 'mime_type=' . $c->stash->{mime_type} ) if $c->debug;
    $id =~ s/\.\w+$//;
    $self->$orig( $c, $id );
};

1;
