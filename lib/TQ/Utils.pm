package TQ::Utils;
use strict;
use warnings;
use Carp;
use Digest::SHA qw( sha256_hex );

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

sub encrypt {
    my $str  = shift;
    my $salt = sha256_hex($str);
    return sha256_hex( $str . $salt );
}

1;
