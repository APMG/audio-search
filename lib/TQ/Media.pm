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
use Text::Wrap;
use Search::Tools::UTF8;

my %NICE_STATUS = (
    A => 'In Process',
    C => 'Complete',
);

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
        duration   => { type => 'integer', },
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
    relationships => [
        jobs => {
            class      => 'TQ::JobQueue',
            type       => 'one to many',
            column_map => { id => 'xid' },
            query_args => [ type => 'M' ],
        },
    ],
);

sub insert {
    my $self = shift;
    $self->uuid( lc( create_uuid_as_string(UUID_V4) ) ) unless $self->uuid;
    $self->SUPER::insert();
}

sub save {
    my $self   = shift;
    my $is_new = $self->id ? 0 : 1;
    my $rt     = $self->SUPER::save(@_);
    if ($is_new) {
        $self->create_job();
    }
    return $rt;
}

sub create_job {
    my $self = shift;
    my $id   = $self->id or confess "must have id set to create job";
    my $uuid = $self->uuid or confess "must have uuid to create job";
    my $job  = TQ::JobQueue->new(
        xid        => $id,
        type       => 'M',
        created_by => $self->user_id,
        cmd        => qq/mk-transcript $uuid/,
    );
    $job->save();
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

    # remember the duration for player preview
    $self->duration( $scan->{info}->{song_length_ms} );

    my $wav16k;
    my $is_mono = $scan->{info}->{channels} == 1 ? 1 : 0;
    if ( $scan->{info}->{samplerate} == 16000 and $is_mono ) {
        $wav16k = $file;
    }
    elsif ( lc $ext eq 'mp3' ) {
        TQ::Utils::run_it( "lame --decode $file $base.wav", $debug );
        TQ::Utils::run_it( "sox $base.wav -r 16000 -c 1 $base-16k.wav",
            $debug );
        $wav16k = "$base-16k.wav";
    }
    elsif ( lc $ext eq 'wav' ) {
        TQ::Utils::run_it( "sox $file -r 16000 -c 1 $base-16k.wav", $debug );
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

    my $json = $jsonfile->slurp;

    # compact the json for storage
    my $transcript = decode_json( Encode::encode_utf8( to_utf8($json) ) );
    return encode_json($transcript);
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

sub transcript_as_text {
    my $self = shift;
    my $columns = shift || 72;
    return '' unless $self->transcript;
    my $decoded
        = decode_json( Encode::encode_utf8( to_utf8( $self->transcript ) ) );
    my $words_array = $decoded->{words};
    my @buf         = ();
    my @section     = ();
    for my $tok (@$words_array) {
        my $word = $tok->{word};
        if ( $word eq '<s>' ) {
            @section = ();
        }
        elsif ( $word eq '</s>' ) {
            push @buf, join( ' ', @section );
        }
        else {
            push @section, $word;
        }
    }

    #dump \@buf;

    local $Text::Wrap::columns = $columns;
    return sprintf( "%s\n", wrap( '', '', @buf ) );
}

sub keywords {
    my $self = shift;
    my $text = $self->transcript_as_text;
    return TQ::Utils::extract_keywords($text);
}

sub nice_status {
    my $self = shift;
    return $NICE_STATUS{ $self->status };
}

sub duration_as_hms {
    my $self = shift;
    my $ms = $self->duration || 0;
    return TQ::Utils::ms2hms($ms);
}

1;
