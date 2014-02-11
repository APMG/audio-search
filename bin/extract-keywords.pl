#!/usr/bin/env perl
#
# Copyright 2014 APMG -- see LICENSE
#
# Extract key nouns/phrases from a file. Non-ascii characters
# are transliterated.
#
#

use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use Lingua::EN::Tagger;
use Search::Tools;
use Search::Tools::Transliterate;

my $usage = "$0 file [...fileN]";
die $usage unless @ARGV;

my $tagger = Lingua::EN::Tagger->new(
    lc                  => 1,
    longest_noun_phrase => 5,
    weight_noun_phrases => 0,
);
my $asciifier = Search::Tools::Transliterate->new( ebit => 0 );

for my $file (@ARGV) {
    my $buf      = Search::Tools->slurp($file);
    my $keywords = extract_keywords($buf);
    for my $word (@$keywords) {
        print "$word\n";
    }
}

sub extract_keywords {
    my ($buf) = @_;

    # deal only with ascii
    $buf = $asciifier->convert($buf);

    # remove any meta markup
    $buf =~ s/#speaker .+?\n//sg;

    # ignore punctuation
    $buf =~ s/[\.\?\!\,\;\:]//g;

    # tagger
    my $tagged = $tagger->add_tags($buf);
    my %nouns  = $tagger->get_noun_phrases($tagged);

    # reduce some parsing noise
    delete $nouns{"'s"};
    for my $k ( keys %nouns ) {
        if ( length $k == 1 ) {
            delete $nouns{$k};
        }
    }

    #dump \%nouns;
    return [ sort { $nouns{$b} <=> $nouns{$a} } keys %nouns ];

}

