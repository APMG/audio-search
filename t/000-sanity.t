#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use lib 'lib';

use_ok('TQ::Config');
is( TQ::Config->get_app_root(), $ENV{PWD}, "get_app_root" );
is( TQ::Config->get_app_port(), 3000, "get_app_port" );

