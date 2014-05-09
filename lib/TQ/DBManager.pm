package TQ::DBManager;
use strict;
use warnings;
use base qw( Rose::DBx::AutoReconnect );
use Carp;
use Data::Dump qw( dump );
use TQ::Config;
use Try::Tiny;

__PACKAGE__->use_private_registry;

my $cfg     = TQ::Config::get_profiles();
my $profile = TQ::Config::get_profile_name();

#warn "profile=$profile";
if ( !TQ::Config::get_profile_value('dbname') ) {
    croak "Invalid profile for $profile";
}

for my $section ( $cfg->Sections ) {
    my %prof = (
        domain   => $section,
        type     => 'slave',
        driver   => 'mysql',
        database => $cfg->val( $section, 'dbname' ),
        host     => ( $cfg->val( $section, 'hostname' ) || 'localhost' ),
        username => $cfg->val( $section, 'username' ),
        password => $cfg->val( $section, 'password' ),
        post_connect_sql =>
            [ 'SET NAMES utf8', qq/SET sql_mode='STRICT_ALL_TABLES'/ ],
        mysql_enable_utf8 => 1,
        server_time_zone  => $cfg->val( $section, 'server_time_zone' ),
    );

    # if there are multiple hostnames, pick one randomly
    if ( $prof{host} =~ m/,/ ) {
        my @hosts = split( /\s*,\s*/, $prof{host} );
        my $random_host = $hosts[ int( rand @hosts ) ];
        $prof{host} = $random_host;
    }

    #dump \%prof;
    __PACKAGE__->register_db(%prof);

    # create master profile
    my %master_prof = %prof;
    $master_prof{type} = 'master';
    if ( $cfg->val( $section, 'write_hostname' ) ) {
        $master_prof{host} = $cfg->val( $section, 'write_hostname' );
    }
    else {
        # use same host since slave==master
    }

    __PACKAGE__->register_db(%master_prof);
}

sub get_write_handle {
    my $self = shift;
    my $domain = ref($self) ? $self->domain : __PACKAGE__->default_domain();
    return __PACKAGE__->new_or_cached( domain => $domain, type => 'master', );
}

# override to optionally return master if BARN_USE_MASTER is set
sub new_or_cached {
    my $class = shift;
    my %arg   = @_;
    $arg{type} ||= 'slave';
    if ( $ENV{TQ_USE_MASTER} ) {
        $arg{type} = 'master';
    }

    # attempt to connect. on slave fatal error, try again with master.
    my $db = try {
        $class->SUPER::new_or_cached(%arg);
    }
    catch {
        warn $_;    # complain with the original error.
        if ( $arg{type} eq 'slave' ) {
            my $db = $class->SUPER::new_or_cached( %arg, type => 'master' );

            # calling new() doesn't try and connect to dbh
            # so just use it for logging.
            my $failed_db = $class->new(%arg);
            $failed_db->logger("failed initial connect, using master");

            return $db;
        }
    };
    return $db;
}

__PACKAGE__->default_type('slave');
__PACKAGE__->default_domain( $ENV{TQ_DOMAIN} || $profile );

1;

