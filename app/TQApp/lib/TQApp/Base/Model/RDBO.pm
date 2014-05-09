package TQApp::Base::Model::RDBO;
use strict;
use warnings;
use base qw( CatalystX::CRUD::Model::RDBO );
use MRO::Compat;
use mro 'c3';
use TQApp::Base::RedactedObject;

__PACKAGE__->config(
    use_lower    => 1,
    object_class => 'TQApp::Base::RedactedObject',
);

1;
