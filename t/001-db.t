#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 5;
use TQ::DBManager;
use Data::Dump qw( dump );

ok( my $db_slave = TQ::DBManager->new_or_cached(), "new db slave" );
$ENV{TQ_USE_MASTER} = 1;
ok( my $db_master = TQ::DBManager->new_or_cached(), "new db master" );
is( $db_master->type, 'master', "master db type" );

$db_slave->logger('ima slave');
$db_master->logger('ima master');

# test slave failure auto-rollover to master
$ENV{TQ_USE_MASTER} = 0;
ok( my $db = TQ::DBManager->new_or_cached( domain => 'master_slave_test' ),
    "get db handle for non-existent slave" );
$db->logger('ima master posing as slave');
is( $db->host, 'localhost', "got master domain" );
