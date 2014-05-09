#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use lib 'lib';

# test media class
{

    package MyTestMedia;
    @MyTestMedia::ISA = ('TQ::Media');
    sub DESTROY { my $u = shift; $u->delete if $u->id; }
}

use_ok('TQ::Media');

my $media_name = 'test media';
my $media_uri  = 'http://somewhereoutthere/foo.wav';

#$Rose::DB::Object::Debug = 1;
#$Rose::DB::Object::Manager::Debug = 1;

ok( my $media = MyTestMedia->new(
        name  => $media_name,
        uri   => $media_uri,
        owner => MyTestMedia->current_user,
        )->save(),
    "new Media"
);

ok( $media->uuid, "media->uuid default set" );
