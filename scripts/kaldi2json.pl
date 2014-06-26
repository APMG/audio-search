#!/usr/bin/env perl
use strict;
use warnings;
use JSON;
use File::Slurp::Tiny qw( read_file read_lines );

my $usage = "$0 dbl_file mlf_file\n";

# take a list of split MLF files from stdin in random order
# and glue them back together in order specified.
# For a single file.

my $scale    = 10_000_000;
my $dbl_file = shift(@ARGV) or die $usage;
my $mlf_file = shift(@ARGV) or die $usage;
my $mlf      = read_file($mlf_file);
my %mlf_hash = ();
while ( $mlf =~ m/\"(.*?)\.rec\"\n(.*?)\n.\n/gs ) {
    $mlf_hash{$1} = $2;
}

my @dbl_lines = read_lines($dbl_file);
my @words     = ();
for my $dbl (@dbl_lines) {
    chomp $dbl;
    my ( $stem, $offset ) = ( $dbl =~ m/^(.*)-(\d+\.\d+)\+\d+\.\d+$/ );
    my $n = 0;
    if ( !exists $mlf_hash{$dbl} ) {
        warn "Failed to find '$dbl' in mlf_file $mlf_file";
        next;
    }
    while ( $mlf_hash{$dbl} =~ m/(\d+)\s*(\d+)\s(.*?)\n/gs ) {
        my $init = $offset + ( $1 / $scale );
        my $dur  = ( $2 / $scale );
        my $word = $3;
        push @words,
            {
            'time'   => $init,
            duration => sprintf( "%.2f", $dur ),
            word     => $word,
            };
    }
}

my $json = encode_json( { words => \@words } );
print $json;
