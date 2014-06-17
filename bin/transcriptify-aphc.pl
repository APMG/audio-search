#!/usr/bin/env perl
#
# Copyright 2014 APMG -- see LICENSE
#
# turn APHC manual transcription file into something a machine can read.
#

use strict;
use warnings;
use File::Slurp::Tiny qw( read_lines );

if ( !@ARGV ) {
    die "$0 file [...fileN]\n";
}

for my $file (@ARGV) {
    my @buf = read_lines($file);
    my @new;

    for my $line (@buf) {
        $line =~ s/^\xEF\xBB\xBF//;    # .docx format inserts BOM sequence

        $line =~ s/\[/\(/gs;
        $line =~ s/\]/\)/gs;
        $line =~ s!\(k\)! k!gm;

        $line =~ s!^(APPLAUSE|LAUGHTER)!#background $1!g;

        # all-CAPS effects in brackets
        $line =~ s!\(([A-Z\ \,]+)\)!\n#background $1\n!g;

        $line =~ s!^([A-Z\ ]+)\:!#speaker $1\n!g;        # speaker names
        $line =~ s!^([\d\.\:]+)\s*!#timestamp $1\n!g;    # timing marks

        # special case for APHC
        $line =~ s!^GK[\,A-Z]+:!#speaker GK\n!gm;

        push @new, $line;
        push @new, "\n";
    }

    # create new buf and zap multi-line patterns
    my $new_buf = join( '', @new );

    # timestamps followed by segment title
    $new_buf =~ s,(#timestamp \S+\n)\n+[^#].+?\n,$1,sg;

    # normalize whitespace a little
    $new_buf =~ s,\n\n+,\n\n,g;

    write_file( $file, $new_buf );
}

