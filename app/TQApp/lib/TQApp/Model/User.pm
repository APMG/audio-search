package TQApp::Model::User;
use strict;
use base qw( TQApp::Base::Model::RDBO );
use MRO::Compat;
use mro 'c3';
use Data::Dump qw( dump );

__PACKAGE__->config(
    name      => 'TQ::User',
    page_size => 50,
);

sub create_related {
    my ( $self, $user, $rel_name ) = @_;
    my $c        = $self->context;
    my $rel_data = $c->req->data;

    # sanity check
    my $relationship = $self->has_relationship( $user, $rel_name )
        or $self->throw_error("no relationship for $rel_name");

    #warn "$rel_name: " . dump($rel_data);

    # make an object we can return
    my $rel_obj = $relationship->class->new(%$rel_data);

    #warn "created new " . $relationship->class;

    my $method = 'add_' . $rel_name;    # TODO based on rel type?
    $user->$method( [$rel_obj] );
    $user->save();

    # wrap it in a CXC Object
    return $self->object_class->new( delegate => $rel_obj );
}

1;
