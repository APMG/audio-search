package TQApp::View::Email;
use Moose;
extends 'Catalyst::View::Email::Template';

__PACKAGE__->config(
    template_prefix => 'email',
    default         => {
        content_type => 'text/plain',
        charset      => 'utf-8',
        view         => 'TTPlain',
    },
    sender => { mailer => 'SMTP', }
);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
