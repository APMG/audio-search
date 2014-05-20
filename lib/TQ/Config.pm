package TQ::Config;
use strict;
use warnings;
use Exporter qw( import );
use Carp;
use Data::Dump qw( dump );
use Sys::Hostname;
use Socket;
use Config::IniFiles;
use Path::Class;

##############
# setup
my $hostname = hostname();
$hostname =~ s/\..+//;
my $user = $ENV{TQ_USER} || $ENV{USER} || $ENV{REMOTE_USER} || 'nobody';
my $path_to_this_pm = file( $INC{"TQ/Config.pm"} );
my $etc_dir      = $path_to_this_pm->dir->absolute->parent->parent . '/etc';
my $profiles_ini = $etc_dir . "/profiles.ini";
my $profiles     = Config::IniFiles->new( -file => $profiles_ini );
my $profile      = $ENV{'TQ_PROFILE'} || get_profile_name();
my $version_file = file( $etc_dir, 'my_version' );
my $version      = '0.001';

if ( -s $version_file ) {
    chomp( $version = $version_file->slurp );
}

# set the global app timezone based on $hostname config
our $TIMEZONE   = $profiles->val( $profile, 'server_time_zone' );
our $SERVER_URI = $profiles->val( $profile, 'server_base_uri' );

##############
# methods

sub get_profile_name {
    my $root = get_app_root();
    my $profile = $root->file( 'etc', 'my_profile' );
    if ( !-s $profile ) {
        return 'dev';
    }
    my $name = $profile->slurp;
    chomp($name);
    return $name;
}

sub get_profile_value {
    my $key = shift or croak "key required";
    return $profiles->val( $profile, $key );
}

sub get_hostname        {$hostname}
sub get_tz              { return $TIMEZONE || 'America/Chicago' }
sub get_datetime_format {'%FT%T%z'}                                 # ISO8601
sub get_profiles        { return $profiles }
sub get_user            { return $user }
sub get_pid             {$$}

sub get_server_base_uri {
    return $SERVER_URI;
}

sub get_app_root {
    return $path_to_this_pm->dir->absolute->parent->parent;
}

sub get_app_port {
    my $uri = get_app_base_uri();
    my ($port) = ( $uri =~ m/:(\d+)/ );
    return $port || 5000;
}

sub get_app_base_uri {
    my $uri = $profiles->val( $profile, 'app_base_uri' )
        || 'http://127.0.0.1:5000';
    return $uri;
}

sub get_log_dir {
    my $log_dir = $profiles->val( $profile, 'log_dir' );
    $log_dir ||= "var";
    return dir($log_dir);
}

sub get_audio_store_path {
    my $p = get_profile_value('audio_store_path');
    $p ||= '/var/extra/audio/store';
    return dir($p);
}

sub get_audio_json_path {
    my $p = get_profile_value('audio_json_path');
    $p ||= '/var/extra/audio/json';
    return dir($p);
}

sub email_from {
    return get_profile_value('email_from') || 'no-reply@nosuchemail.org';
}

sub get_app_has_media_player {
    return get_profile_value('app_has_media_player');
}

1;
