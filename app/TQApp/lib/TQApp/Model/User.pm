package TQApp::Model::User;
use strict;
use base qw( TQApp::Base::Model::RDBO );
use MRO::Compat;
use mro 'c3';

__PACKAGE__->config(
    name      => 'TQ::User',
    page_size => 50,
);

1;
