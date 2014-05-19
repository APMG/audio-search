package TQApp::Controller::Media;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

sub index : Path : Args(1) {
    my ( $self, $c, $uuid ) = @_;
    $c->authenticate( {}, "tqapp" );
    my $media = try {
        $c->model('Media')->fetch( uuid => $uuid );
    }
    catch {
        $c->stash( template => '404.tt' );
        $c->res->status(404);
        return 0;
    } or return;
    $c->stash( media => $media, template => 'media/index.tt' );
}

__PACKAGE__->meta->make_immutable;

1;
