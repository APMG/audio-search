package TQApp::Auth::Store;
use Moose;
use namespace::autoclean;
use TQ::User;
use TQApp::Auth::User;
use TQApp::Auth::Realm;

has 'config' => ( is => 'rw', isa => 'HashRef', required => 1, );
has 'debug' => ( is => 'rw', isa => 'Bool' );

sub new {
    my ( $class, $config, $app ) = @_;
    my $self = bless( {}, $class );
    $self->config($config);    # cache for later
    $self->debug( $config->{debug}
            || $ENV{CATALYST_DEBUG}
            || $ENV{PERL_DEBUG}
            || 0 );

    return $self;
}

sub find_user {
    my ( $self, $userinfo, $c ) = @_;

    $c->log->debug('AuthStore: authenticating request') if $self->debug;

    my $email = $userinfo->{username};

    my $user = TQ::User->new( email => $email )->load_speculative;

    if ( !$user or $user->status ne 'A' ) {
        return;
    }

    return TQApp::Auth::User->new( id => $email, user => $user );
}

sub for_session {
    my ( $self, $c, $user ) = @_;
    return { email => $user->email };
}

sub from_session {
    my ( $self, $c, $frozen_user ) = @_;
    return $frozen_user;
}

1;
