package TQApp::Base::Model::RDBO;
use strict;
use warnings;
use base qw( CatalystX::CRUD::Model::RDBO );
use MRO::Compat;
use mro 'c3';

__PACKAGE__->config( use_lower => 1, );

1;
