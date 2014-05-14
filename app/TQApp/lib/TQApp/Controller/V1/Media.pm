package TQApp::Controller::V1::Media;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TQApp::Base::Controller::API' }

__PACKAGE__->config(
    model_name  => 'Media',
    primary_key => 'uuid',
);

1;
