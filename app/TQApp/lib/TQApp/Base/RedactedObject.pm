package TQApp::Base::RedactedObject;
use Moose;
extends 'CatalystX::CRUD::Object::RDBO';

# some attributes we want to hide

my @redacted = qw( id pw created_by updated_by );

around 'serialize' => sub {
    my ( $super_method, $self ) = @_;
    my $hashref = $self->$super_method();
    for my $attr (@redacted) {
        delete $hashref->{$attr} if exists $hashref->{$attr};
    }
    return $hashref;
};

1;
