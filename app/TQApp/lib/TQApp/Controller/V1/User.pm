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
    $c->log->debug( "send confirmation email to user " . $user->email );
    my %email = (
        to           => $user->email,
        from         => $c->config->{email_from},
        subject      => $c->config->{name} . ' account confirmation',
        template     => 'user_confirmation.tt',
    );
    $c->stash( email => \%email );
    $c->forward( $c->view('Email') );
}

__PACKAGE__->meta->make_immutable();

1;
