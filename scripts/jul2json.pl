#!/usr/bin/env perl
use strict;
use warnings;
use JSON;
use File::Slurp::Tiny qw( read_file read_lines );

my $usage = "$0 dbl_file mlf_file\n";

# take a list of split MLF files from stdin in random order
# and glue them back together in order specified.
# For a single file.

my $scale     = 10_000_000;
my $dbl_file  = shift(@ARGV) or die $usage;
my $mlf_file  = shift(@ARGV) or die $usage;
my $mlf       = read_file($mlf_file);
my @dbl_lines = read_lines($dbl_file);

my %mlf_hash    = ();
my %confidences = ();
my %misc;
while ( $mlf
    =~ m/input speechfile: (.*?)\.wav\n(.*?)\ncmscore1: (.*?)\n.*? ----------------------------------------\n(.*?\n)re-computed AM score:/gs
    )
{
    my $filename = $1;
    $mlf_hash{$filename}    = $4;
    $confidences{$filename} = $3;
    $misc{$filename}        = $2;
}

my @words = ();
for my $dbl (@dbl_lines) {
    chomp $dbl;
    my ( $stem, $offset ) = ( $dbl =~ m/^(.*)-(\d+\.\d+)\+\d+\.\d+$/ );

    my @conf = split( / /, $confidences{$dbl} );
    if ( $misc{$dbl}
        =~ /00 _default: got no candidates, output 1st pass result as a final result/
        )
    {
        s/0.000/undefined/ for @conf;
    }
    my $n = 0;
    while ( $mlf_hash{$dbl} =~ m/\[ *(\d+) +(\d+)\].*? +(.*?)  (.*?)\t/gs ) {
        my $init = ( $offset + 0.01 * $1 );
        my $quit = ( $offset + 0.01 * ( $2 + 1 ) );
        my $dur  = ( $quit - $init );
        my $word = $4;
        push @words,
            {
            'time'     => $init,
            duration   => sprintf( "%6.2f", $dur ),
            word       => $word,
            confidence => $conf[ $n++ ],
            };
    }
}

my $json = encode_json( { words => \@words } );
print $json;
