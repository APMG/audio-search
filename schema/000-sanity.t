#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;
use Data::Dump qw( dump );

pass("Schema update infrastructure sanity check");

use schema::helpers;

ok( !schema::helpers::table_exists('nosuchtable'),
    "nosuchtable does not exist" );
ok( schema::helpers::table_exists('users'), "users table exists" );
ok( my $dummy = schema::helpers::table_class( 'users', 'MyUser' ),
    "dummy table_class" );
ok( schema::helpers::has_column( $dummy, 'id' ),
    "users table has id column" );
ok( $dummy->init_db->isa('Rose::DB'), "init_db returns Rose::DB object" );

ok( my $ddl_statements = schema::helpers::read_tq_ddl(), "read_tq_ddl" );

#diag( dump $ddl_statements );

