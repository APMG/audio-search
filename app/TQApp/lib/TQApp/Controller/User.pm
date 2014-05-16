package TQApp::Controller::User;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

sub confirm : Local Args(1) {
    my ( $self, $c, $guid ) = @_;

    # look up user and toggle their status
    my $user = try {
        $c->model('User')->fetch( guid => $guid )->delegate;
    }
    catch {
        $c->log->error("Can't find guid $guid");
        return 0;
    };

    if ( !$user or $user->status ne 'T' ) {
        $c->res->status(404);
        $c->stash( template => '404.tt' );
        return;
    }

    $user->status('A');
    $user->save();
    $c->stash( user => $user, template => 'user/confirm.tt' );
}

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->authenticate( {}, "tqapp" );
    $c->stash( user => $c->user->user, template => 'user/index.tt' );
}

__PACKAGE__->meta->make_immutable;

1;
