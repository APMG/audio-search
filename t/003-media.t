#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
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

ok( my $job = $media->jobs->[0], "one job created" );
is( $job->cmd, sprintf( "mk-transcript %s", $media->uuid ), "job cmd" );
is( $job->type, 'M', "job->type == M" );

# clean up
$job->delete;
