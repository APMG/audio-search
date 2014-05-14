package TQApp::Model::Media;
use strict;
use base qw( TQApp::Base::Model::RDBO );
use MRO::Compat;
use mro 'c3';
use Data::Dump qw( dump );

__PACKAGE__->config(
    name      => 'TQ::Media',
    page_size => 50,
);

1;
