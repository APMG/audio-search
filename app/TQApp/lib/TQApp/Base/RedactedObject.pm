package TQApp::Base::RedactedObject;
use Moose;
extends 'CatalystX::CRUD::Object::RDBO';
use TQ::Utils qw( parse_date );

# some attributes we want to hide

my @redacted = qw( id pw created_by updated_by user_id xid api_key );

sub serialize {
    my $self = shift;
    my $hashref = $self->delegate->as_tree( depth => 1 );
    return $self->_redact($hashref);
}

sub _redact {
    my ( $self, $hashref ) = @_;
    for my $attr (@redacted) {
        delete $hashref->{$attr} if exists $hashref->{$attr};
    }

    # make sure datetime stringifys as iso8601 with timezone
    for my $dtcol (qw( created_at updated_at )) {
        if ( defined $hashref->{$dtcol} ) {
            $hashref->{$dtcol} = parse_date( $hashref->{$dtcol} ) . "";
        }
    }

    # same thing for any column looks like datetime
    # or looks like child object.
    for my $col ( keys %$hashref ) {
        next unless defined $hashref->{$col};
        if ( $col =~ m/_dtim$/ ) {
            $hashref->{$col} = parse_date( $hashref->{$col} ) . "";
        }
        if ( ref $hashref->{$col} eq 'ARRAY' ) {
            for my $child ( @{ $hashref->{$col} } ) {
                $self->_redact($child);    # acts in-place so ignore return
            }
        }
        elsif ( ref $hashref->{$col} eq 'HASH' ) {
            $self->_redact( $hashref->{$col} );
        }

    }

    return $hashref;
}

1;
