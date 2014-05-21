package TQApp::Controller::V1;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

use JSON;

# https://github.com/SPORE/specifications
sub index : Path {
    my ( $self, $c ) = @_;

    my $spore = {
        name         => 'TQ',
        version      => '1.0',
        api_base_url => $c->uri_for('') . '',
        api_format   => [qw( JSON )],
        description => 'The TQ (Transcript Queue) service transcribes audio.',
        methods     => [

            # /user
            {   method      => 'GET',
                path        => '/v1/user/:guid',
                description => 'the User for :guid',
            },
            {   method      => 'GET',
                path        => '/v1/user',
                description => 'all Users to which you are authorized',
            },
            {   method      => 'POST',
                path        => '/v1/user',
                description => 'create a new User',
            },
            {   method      => 'PUT',
                path        => '/v1/user/:guid',
                description => 'update an existing User',
            },
            {   method      => 'DELETE',
                path        => '/v1/user/:guid',
                description => 'delete User :guid'
            },
            {   method      => 'GET',
                path        => '/v1/user/:guid/media',
                description => 'get all Media for User :guid',
            },
            {   method      => 'POST',
                path        => '/v1/user/:guid/media',
                description => 'create new Media for User :guid',
            },

            # /media
            {   method      => 'GET',
                path        => '/v1/media/:uuid',
                description => 'the Media for :uuid',
            },
            {   method      => 'GET',
                path        => '/v1/media',
                description => 'all Media to which you are authorized',
            },
            {   method      => 'POST',
                path        => '/v1/media',
                description => 'create a new Media',
            },
            {   method      => 'PUT',
                path        => '/v1/user/:uuid',
                description => 'update an existing Media',
            },
            {   method      => 'DELETE',
                path        => '/v1/media/:uuid',
                description => 'delete Media :uuid'
            },
        ]
    };

    $c->res->body( encode_json($spore) );
    $c->res->content_type('application/json');

}

1;
