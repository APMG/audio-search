package TQApp::View::TTPlain;
use Moose;
extends 'Catalyst::View::TT';

use Data::Dump qw( dump );

__PACKAGE__->config(
    #DEBUG => 'all',

    # any TT configuration items go here
    TEMPLATE_EXTENSION => '.tt',
    CATALYST_VAR       => 'c',
    TIMER              => 0,
    ENCODING           => 'utf-8',
    render_die => 1,    # Default for new apps, see render method docs
);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

