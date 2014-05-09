package TQApp::Base::Controller::API;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::CRUD::Controller::REST' }

__PACKAGE__->config(
    default                => 'application/json',
    content_type_stash_key => 'mime_type',
    page_size              => 50,
);

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
