package TQ::Utils;
use strict;
use warnings;
use TQ::Config;
use Carp;
use Digest::SHA qw( sha256_hex );
use DateTime::Format::DateParse;
use Rose::DateTime::Util ();
use Path::Class;
use Lingua::EN::Tagger;
use Search::Tools::Transliterate;

use base 'Exporter';
our @EXPORT_OK = qw( logger parse_date random_str encrypt );

=head2 random_str([I<len>])

Returns a random alphanumeric string of length I<len>. Default
length is 10.

Unlike random() (which includes the - character), random_str()
is seeded soley on the alpha char set, and not the current time,
so it will not be truly as 'random' as random. But for casual
use, it requires less processing overhead than random().

=cut

sub random_str {
    my $self = shift;
    my $n = shift || 16;
    if ( $n =~ m/\D/ ) {
        croak "error: 'n' must be a positive integer";
    }
    my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
    return join( "", @chars[ map { rand @chars } ( 1 .. $n ) ] );
}

=head2 encrypt( I<str> )

Returns I<str> encrypted, one-way.

=cut

sub encrypt {
    my $str  = shift;
    my $salt = sha256_hex($str);
    return sha256_hex( $str . $salt );
}

=head2 logger( I<msg> )

Prints I<msg> to STDOUT with standard timestamp, hostname, prefix.

=cut

sub logger {
    local $| = 1;
    binmode STDOUT, ':utf8';
    printf( "[%s][%s][%s] %s",
        TQ::Config::get_hostname(),
        scalar localtime(),
        $$, join( ' ', @_ ) );
}

=head2 run_it( I<cmd>[, I<verbose_mod>] )

Wrapper around IPC::Cmd::run. Returns the full_buffer output of an external
system call, dying on any error.

Pass a true value for I<verbose_mode> to see output on stderr.

=cut

sub run_it {
    my $cmd = shift;
    my $verbose = shift || 0;
    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf )
        = IPC::Cmd::run( command => $cmd, verbose => $verbose );

    # croak on any error. This introduces potential bottleneck if one
    # file fails, since nothing else will get processed. However,
    # in this early stage of development we'll live with that danger
    # because we'd rather troubleshoot the command.
    if ( !$success ) {
        croak "$cmd failed with [$error_code]: " . join( "\n", @$stderr_buf );
    }
    return $full_buf;
}

=head2 parse_date( I<date_str> )

Returns a DateTime object for I<date_str> defaulting to the
timezone in TQ::Config::get_tz().

=cut

sub parse_date {
    if ( @_ > 1 ) {
        shift(@_);    # discard if called as method
    }

    my $date = shift or croak "date required";
    $ENV{TQ_TESTING} and carp "date=$date";
    return Rose::DateTime::Util::parse_date( $date, TQ::Config::get_tz() )
        || DateTime::Format::DateParse->parse_datetime($date);
}

=head2 format_date( I<datetime> )

Returns a string for I<datetime> using TQ::Config::get_datetime_format()
and TQ::Config::get_tz().

=cut

sub format_date {
    if ( @_ > 1 ) {
        shift(@_);
    }
    my $dt = shift;
    if ( !defined($dt) or !$dt->isa('DateTime') ) {
        confess "DateTime object required";
    }
    $dt->set_time_zone( TQ::Config::get_tz() );
    return $dt->strftime( TQ::Config::get_datetime_format() );
}

# monkey-patch datetime alas DateTimeX::TO_JSON
{
    no warnings;

    sub DateTime::TO_JSON {
        my $dt = shift;
        return format_date($dt);
    }

    sub DateTime::_stringify {
        my $dt = shift;
        return format_date($dt);
    }
}

=head2 seg_path_for( I<pk>, I<base_dir> [,I<depth>] )

Returns a Path::Class::Dir object relative to I<base_dir>
segmented based on the first 2 chars in I<pk>.

Optional I<depth> should be an integer indicating number
of levels of segmentation to apply. Default is 2.

=cut

sub seg_path_for {
    my $pk       = shift;
    my $base_dir = dir(shift);
    my $depth    = shift || 2;
    my @chars    = split( //, $pk );
    my @levels;
    while ( @chars and @levels < $depth ) {
        my $char = shift @chars;
        next unless $char =~ m/^\w$/;
        push @levels, $char;
    }
    return $base_dir->subdir(@levels);
}

=head2 secs2hms( I<seconds> )

Converts I<seconds> to hh:mm:ss string.

=cut

sub secs2hms {
    my $secs  = shift || 0;
    my $hours = int( $secs / 3600 );
    my $rm    = $secs % 3600;
    my $min   = int( $rm / 60 );
    my $sec   = $rm % 60;
    return sprintf( "%02d:%02d:%02d", $hours, $min, $sec );
}

=head2 hms2secs( I<hh:mm::ss> )

Converts I<hh:mm:ss> to seconds.

=cut

sub hms2secs {
    my $hhmmss = shift || return 0;
    my ( $h, $m, $s ) = split( /:/, $hhmmss );
    my $secs = 0;
    $secs += $s;
    $secs += ( $m * 60 );
    $secs += ( $h * 3600 );
    return $secs;
}

=head2 ms2hms( I<milliseconds> )

Returns I<hh:mm::ss>.

=cut

sub ms2hms {
    my $ms    = shift;
    my $secs  = int( $ms / 1000 );
    my $hours = int( $secs / 3600 );
    my $rm    = $secs % 3600;
    my $min   = int( $rm / 60 );
    my $sec   = $rm % 60;
    return sprintf( "%02d:%02d:%02d", $hours, $min, $sec );
}

my $tagger = Lingua::EN::Tagger->new(
    lc                  => 1,
    longest_noun_phrase => 10,
    weight_noun_phrases => 0,
);
my $asciifier = Search::Tools::Transliterate->new( ebit => 0 );

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

sub send_email {
    require Template;
    require Email::Sender::Simple;
    require Email::Simple;
    require Email::Simple::Creator;

    my %email    = @_;
    my $tmpl     = delete $email{tmpl} or confess "tmpl name required";
    my $tmpl_dir = TQ::Config::get_app_root->subdir('app/TQApp/root/email');
    my $template = Template->new( { INCLUDE_PATH => "$tmpl_dir" } );
    my $body     = '';
    $template->process( $tmpl, \%email, \$body )
        or confess $template->error();
    my $email = Email::Simple->create(
        header => [
            To      => delete $email{to},
            From    => TQ::Config::email_from(),
            Subject => delete $email{subject},
        ],
        body => $body,
    );
    Email::Sender::Simple->send($email);
}

1;
