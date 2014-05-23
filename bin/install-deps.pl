#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use TQ::Utils qw( run_it );

# download sf.net dependencies and install them

my $verb               = 1;
my $acoustic_model_pkg = 'acoustic-model-0.6.tar.gz';
my $language_model_pkg = 'language-model-0.6.tar.gz';
my $cmuseg_pkg         = 'CMUseg_0.5.tar.gz';

sub get_sf_url {
    my $file = shift or die "file required";
    return
        sprintf(
        "https://downloads.sourceforge.net/project/apmaudiosearch/%s?use_mirror=master",
        $file );
}

# models unpack into etc/
run_it(
    sprintf(
        "wget %s && tar xvfz %s",
        get_sf_url($acoustic_model_pkg),
        $acoustic_model_pkg
    ),
    $verb
);
run_it(
    sprintf(
        "wget %s && tar xvfz %s",
        get_sf_url($language_model_pkg),
        $language_model_pkg
    ),
    $verb
);

# cmuseg goes in tools
run_it(
    sprintf(
        "cd tools && wget %s && tar xvfz %s",
        get_sf_url($cmuseg_pkg), $cmuseg_pkg
    ),
    $verb
);

# NOTE cmuseg contains pre-compiled binaries, which at this point we trust.

# run the cantab install script
run_it( "sh install.sh", $verb );
