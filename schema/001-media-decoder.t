#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dump qw( dump );
use schema::helpers;

ok( my $media_ddl = schema::helpers::get_table_def('media'),
    "get media ddl" );
if ( $media_ddl =~ m/decoder/ ) {
    pass('media.decoder column exists');
}
else {
    ok( $schema::helpers::db->dbh->do(
            "alter table media add column decoder char(1) default 'K' not null"
        ),
        "create media.decoder column"
    );
}

done_testing();
