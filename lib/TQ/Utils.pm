package TQ::Utils;
use strict;
use warnings;
use TQ::Config;
use Carp;
use Digest::SHA qw( sha256_hex );
use DateTime::Format::DateParse;
use Rose::DateTime::Util ();

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

Returns a string for I<datetime> using TQ::Config::get_pubdtim_format()
and TQ::Config::get_tz().

=cut

sub format_date {
    if ( @_ > 1 ) {
        shift(@_);
    }
    my $dt = shift;
    if ( !$dt or !$dt->isa('DateTime') ) {
        confess "DateTime object required";
    }
    $dt->set_time_zone( TQ::Config::get_tz() );
    return $dt->strftime( TQ::Config::get_pubdtim_format() );
}

1;
