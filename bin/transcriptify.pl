#!/usr/bin/env perl
#
# Copyright 2014 APMG -- see LICENSE
#
# turn manual transcription file into something a machine can read.
#

use strict;
use warnings;
use File::Slurp;

my $file = shift or die "$0 file";
my @buf = read_file($file);
my @new;

for my $line (@buf) {
    $line =~ s/^\xEF\xBB\xBF//;    # .docx format inserts BOM sequence

    # fixes from cantab
    $line =~ s/\[/\(/gs;
    $line =~ s/\]/\)/gs;
    $line =~ s!\(k\)! k!gm;
    $line =~ s!^\(([^\n]*)\)!#background $1!gm;     #brackets on a new line
    $line =~ s!\(([^\s]*)\)!\n#background $1!gs;    #one word in brackets

    #special cases
    $line =~ s!\(speaking\sVietnamese\)!\n#background speaking\_Vietnamese!gs;
    $line =~ s!\(makes\snoise\)!\n#background makes\_noise!gs;

    #$line =~ s!^([^a-z\n]*)\:!#speaker $1\n!gm;     #comment speaker names

    if ( $line =~ m/^([\w\.\-\ ]+): ./s ) {
        my ( $who, $what ) = ( $line =~ m/^(.+?):\ *(.+)$/s );
        push @new, "#speaker $who\n$what";
    }
    else {
        push @new, $line;
    }
    push @new, "\n";
}

write_file($file, @new);

