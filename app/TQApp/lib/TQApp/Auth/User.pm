package TQApp::Auth::User;
use Moose;
extends 'Catalyst::Authentication::User';
use namespace::autoclean;
use Data::Dump qw( dump );

has 'id'   => ( is => 'rw', isa => 'Str',      required => 1 );
has 'user' => ( is => 'rw', isa => 'TQ::User', required => 1 );

sub roles { return [ shift->user->type ] }
my %features = ( session => 1, roles => { self_check => 0 }, );
sub supported_features { return \%features }

sub check_password {
    my ($self, $pw) = @_;
    return $self->user->check_password($pw); 
}

1;
