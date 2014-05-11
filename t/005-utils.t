#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;
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
