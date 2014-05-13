package TQ::Media;
use strict;
use warnings;
use base qw( TQ::DB );
use Carp;
use Data::Dump qw( dump );
use UUID::Tiny ':std';
use TQ::Config;
use TQ::Utils;
use LWP::UserAgent;
use Audio::Scan;
use JSON;

__PACKAGE__->meta->setup(
    table   => 'media',
    columns => [
        id         => { type => 'serial',  not_null => 1 },
        uuid       => { type => 'char',    length   => 36, not_null => 1 },
        name       => { type => 'varchar', length   => 255, },
        transcript => { type => 'text',    length   => 16_777_215 },
        uri        => { type => 'text',    length   => 65535 },
        status => {
            type     => 'char',
            length   => 1,
            default  => 'A',
            not_null => 1,
        },
        user_id    => { type => 'integer',  not_null => 1, },
        created_by => { type => 'integer',  not_null => 1 },
        updated_by => { type => 'integer',  not_null => 1 },
        created_at => { type => 'datetime', not_null => 1 },
        updated_at => { type => 'datetime', not_null => 1 },
    ],
    primary_key_columns => ['id'],
    unique_keys         => ['uuid'],
    foreign_keys        => [
        created_user => {
            class       => 'TQ::User',
            key_columns => { created_by => 'id' },
        },
        updated_user => {
            class       => 'TQ::User',
            key_columns => { updated_by => 'id' },
        },
        owner => {
            class       => 'TQ::User',
            key_columns => { 'user_id' => 'id' },
        },
    ],

);

sub insert {
    my $self = shift;
    $self->uuid( lc( create_uuid_as_string(UUID_V4) ) ) unless $self->uuid;
    $self->SUPER::insert();
}

sub primary_key_uri_escaped {
    my $self = shift;
    return $self->uuid;
}

sub transcribe {
    my $self = shift;
    my %args = @_;

    my $converter = delete $args{converter} or confess "converter required";
    my $file     = delete $args{file}  || $self->get_file;
    my $jsonfile = delete $args{json}  || $self->get_json_file;
    my $debug    = delete $args{debug} || 0;

    # we require 16k wav format. make sure we have it.
    # Audio::Scan relies on file extension so we do too.
    my ( $base, $ext ) = ( $file =~ m/^(.+)\.(\w+)$/ );
    my $scan = Audio::Scan->scan_info($file);
    $debug and warn dump $scan->{info};
    $debug and warn sprintf( "length: %s\n",
        TQ::Utils::ms2hms( $scan->{info}->{song_length_ms} ) );
    my $wav16k;
    if ( $scan->{info}->{samplerate} == 16000 ) {
        $wav16k = $file;
    }
    elsif ( lc $ext eq 'mp3' ) {
        TQ::Utils::run_it("lame --decode $file $base.wav");
        TQ::Utils::run_it("sox $base.wav -r16k $base-16k.wav");
        $wav16k = "$base-16k.wav";
    }
    elsif ( lc $ext eq 'wav' ) {
        TQ::Utils::run_it("sox $file -r16k $base-16k.wav");
        $wav16k = "$base-16k.wav";
    }
    else {
        confess "Failed to create 16k wav file from $file";
    }

    $jsonfile->parent->mkpath;

    my $start = time();
    my $out   = TQ::Utils::run_it("$converter $wav16k $jsonfile");
    my $end   = time();
    $debug
        and warn
        sprintf( "elapsed: %s\n", TQ::Utils::secs2hms( $end - $start ) );
    $debug and warn sprintf( "%s\n", join( "", @$out ) );

    return $jsonfile->slurp;
}

sub get_json_file {
    my $self    = shift;
    my $jsondir = TQ::Utils::seg_path_for( $self->uuid,
        TQ::Config::get_audio_json_path(), 4 );
    return $jsondir->file( $self->uuid . '.json' );
}

sub get_file {
    my $self = shift;
    my $force = shift || 0;

    my $uri = $self->uri;
    my $file;
    if ( -s $uri ) {
        $file = $uri;
    }
    else {
        # fetch and normalize
        my ($ext) = ( $uri =~ m/\.(\w+)$/ );
        my $ua    = LWP::UserAgent->new();
        my $dir   = TQ::Utils::seg_path_for( $self->uuid,
            TQ::Config::get_audio_store_path(), 4 );
        $dir->mkpath;
        $file = $dir->file( $self->uuid . '.' . $ext );
        if ( -s $file and !$force ) {

            # already there
        }
        else {
            # fetch it
            my $resp = $ua->mirror( "$uri", "$file" );
            printf( "Mirror: %s\n%s\n", $uri, $resp->headers->as_string );
        }
    }
    return $file;
}

1;
