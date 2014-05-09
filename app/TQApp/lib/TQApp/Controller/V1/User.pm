package TQApp::Controller::V1::User;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TQApp::Base::Controller::API' }

__PACKAGE__->config(
    model_name  => 'User',
    primary_key => 'guid',
);

1;
