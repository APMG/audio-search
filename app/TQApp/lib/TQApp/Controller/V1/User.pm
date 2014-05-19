package TQApp::Controller::V1::User;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TQApp::Base::Controller::API' }

__PACKAGE__->config(
    model_name  => 'User',
    primary_key => 'guid',
);

around 'zero_args_POST' => sub {
    my ( $super_method, $self, $c ) = @_;
    $self->$super_method($c);
    if ( $c->res->status =~ m/^2/ ) {

        # new User. send confirmation email.
        $self->send_confirmation_email($c);
    }
};

sub send_confirmation_email {
    my ( $self, $c ) = @_;
    my $user = $c->stash->{object};
    $c->log->debug( "send confirmation email to user " . $user->email )
        if $c->debug;
    my %email = (
        to       => $user->email,
        from     => TQ::Config::email_from(),
        subject  => $c->config->{name} . ' account confirmation',
        template => 'user_confirmation.tt',
    );
    $c->stash( email => \%email );
    $c->forward( $c->view('Email') );
}

around 'fetch' => sub {
    my ( $super_method, $self, $c, $guid ) = @_;

    # user can only read itself
    if ( $c->stash->{user}->guid eq $guid ) {
        return $self->$super_method( $c, $guid );
    }
    $self->status_forbidden( $c, message => 'Permission denied' );
    $c->stash( fetch_failed => 1 );    # trigger abort elsewhere
    return;
};

sub can_write {
    my ( $self, $c ) = @_;

    # user can only write itself
    if ( $c->stash->{user}->guid eq $c->stash->{object}->guid ) {
        return 1;
    }
    return 0;
}

__PACKAGE__->meta->make_immutable();

1;
