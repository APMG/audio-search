#!/usr/bin/env perl
use strict;
use warnings;
use JSON;
use File::Slurp::Tiny qw( read_file read_lines );
use Data::Dump qw( dump );

my $usage = "$0 dbl_file mlf_file\n";

# take a list of split MLF files from stdin in random order
# and glue them back together in order specified.
# For a single file.

my $scale    = 10_000_000;
my $dbl_file = shift(@ARGV) or die $usage;
my $mlf_file = shift(@ARGV) or die $usage;
my $mlf      = read_file($mlf_file);
my %mlf_hash = ();

# zap first line
$mlf =~ s,^#!MLF!#\n,,;

# split on record delimiter
my @mlf_recs = split( m/\n\.\n/, $mlf );

#dump \@mlf_recs;

# build hash of records
for my $mlf_rec (@mlf_recs) {
    my @lines = split( /\n/, $mlf_rec );
    my $file = shift @lines;
    $file =~ s,^.*/,,;
    $file =~ s/\.rec//;
    $file =~ s/"//g;
    $mlf_hash{$file} = \@lines;
}

#dump \%mlf_hash;

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
    for my $line ( @{ $mlf_hash{$dbl} } ) {
        chomp $line;
        my @parts = split( /\ +/, $line );

        #warn "$line => " . dump \@parts;
        my $init = $offset + ( $parts[0] / $scale );
        my $dur  = ( $parts[1] / $scale );
        my $word = $parts[2];
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
