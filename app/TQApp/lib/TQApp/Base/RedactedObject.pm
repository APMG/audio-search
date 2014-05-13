package TQApp::Base::RedactedObject;
use Moose;
extends 'CatalystX::CRUD::Object::RDBO';
use TQ::Utils qw( parse_date );

# some attributes we want to hide

my @redacted = qw( id pw created_by updated_by user_id xid );

around 'serialize' => sub {
    my ( $super_method, $self ) = @_;
    my $hashref = $self->$super_method();
    for my $attr (@redacted) {
        delete $hashref->{$attr} if exists $hashref->{$attr};
    }

    # make sure datetime stringifys as iso8601 with timezone
    for my $dtcol (qw( created_at updated_at )) {
        if ( exists $hashref->{$dtcol} ) {
            $hashref->{$dtcol} = parse_date( $hashref->{$dtcol} ) . "";
        }
    }

    return $hashref;
};

1;
