#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;
use lib 'lib';
use JSON;

use_ok('TQ::Utils');
ok( my $dt  = TQ::Utils::parse_date('now'), "parse_date(now)" );
ok( my $now = TQ::Utils::format_date($dt),  "format_date(dt)" );
is( JSON->new->convert_blessed(1)->encode( [$dt] ),
    qq/["$now"]/,
    "format_date monkey-patched TO_JSON"
);
is( "$dt", $now, "monkey-patched DateTime stringify" );

#diag($now);

is( TQ::Utils::seg_path_for( 'foo', '/path/to' ),
    "/path/to/f/o", "seg_path_for default" );
is( TQ::Utils::seg_path_for( 'foo', '/path/to', 3 ),
    "/path/to/f/o/o", "seg_path_for simple" );
is( TQ::Utils::seg_path_for( 'f-o_o', '/path/to', 6 ),
    "/path/to/f/o/_/o", "seg_path_for adv" );
