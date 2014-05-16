package TQ::JobQueue;
use strict;
use warnings;
use base qw( TQ::DB );
use Carp;
use IPC::Cmd ();
use TQ::Config;
use UUID::Tiny ':std';
use Data::Dump qw( dump );

# TODO use TQ::Config for this
my $MAX_PER_QUEUE = 10;

__PACKAGE__->meta->setup(
    table => 'job_queue',

    columns => [
        id   => { type => 'serial',  not_null => 1 },
        host => { type => 'varchar', length   => 255, },
        pid  => { type => 'integer', },
        cmd       => { type => 'text', not_null => 1, length => 65535 },
        error_msg => { type => 'text', length   => 65535, },
        type => { type => 'character', length => 1, },
        xid  => { type => 'integer', },
        uuid => { type => 'char', length => 36, not_null => 1 },
        schedule_dtim => { type => 'datetime', },
        start_dtim    => { type => 'datetime' },
        complete_dtim => { type => 'datetime' },
        created_by    => { type => 'integer', not_null => 1 },
        updated_by    => { type => 'integer', not_null => 1 },
        created_at    => { type => 'datetime', not_null => 1 },
        updated_at    => { type => 'datetime', not_null => 1 },
    ],

    primary_key_columns => ['id'],
    unique_keys         => [ ['uuid'] ],

    foreign_keys => [
        created_user => {
            class       => 'TQ::User',
            key_columns => { created_by => 'id' },
        },
        updated_user => {
            class       => 'TQ::User',
            key_columns => { updated_by => 'id' },
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

=head2 add_job( I<cmd>[, I<start_after>] )

Class method. Creates a new object for I<cmd> and returns $jobqueue object.

Optional I<start_after> value should be a valid value for schedule_dtim.

=cut

sub add_job {
    my $class = shift;
    my $cmd   = shift or croak "cmd required";
    my $after = shift;
    my $self  = $class->new( cmd => $cmd, schedule_dtim => $after );
    $self->save();
    return $self;
}

sub run {
    my $self     = shift;
    my %arg      = @_;
    my $hostname = $arg{hostname} || TQ::Config->get_hostname();

    # if this job was queued by/for some other host
    # confirm we have the right host.
    if ( $self->host and $self->host ne $hostname ) {
        confess sprintf( "Job %d queued for host %s but this is host %s\n",
            $self->id, $self->host, $hostname );
    }
    my $cmd     = $self->cmd;
    my $root    = TQ::Config::get_app_root();
    my $log_dir = TQ::Config::get_log_dir();
    my $perl    = $^X;

    # simple interpolation
    $cmd =~ s/TQ_ROOT/$root/g;
    $cmd =~ s/LOG_DIR/$log_dir/g;
    if ( !$cmd ) {
        confess "cmd is empty for job id " . $self->id;
    }

    # may only run things from our bin (limited PATH)
    my ($exe) = ( $cmd =~ m/^(\S+)/ );
    if ( $exe =~ m!/! or !-s $root->subdir('bin')->file($exe) ) {
        Carp::cluck
            sprintf(
            "job %d seems to call an executable in an invalid PATH (%s)",
            $self->id, $exe );
        $self->error_msg("Invalid path: $exe");
        $self->complete_dtim( time() );
        $self->save();
        return 0;
    }
    else {
        $cmd = "$root/bin/$cmd";
    }

    my $debug = $ENV{TQ_DEBUG} || 0;

    # make sure this perl is first in PATH
    $perl =~ s/\/perl$//;
    $ENV{PATH} = $perl . ':' . $ENV{PATH};

    # job meta
    $self->pid($$);
    $self->host($hostname);    # in case it is undef
    $self->start_dtim( time() );
    $self->save();

    my ( $success, $error_msg, $full_buf, $stdout_buf, $stderr_buf )
        = IPC::Cmd::run( command => $cmd, verbose => $debug );

    #warn "success=$success error_msg=$error_msg \$\?=$? \$\!=$!\n";

    $self->complete_dtim( time() );

    if ( !$success ) {

        # truncate any overly-long error messages
        my $jq_error_msg = join( "\n", $error_msg, @$full_buf );
        my $maxlen = $self->meta->column('error_msg')->length;
        if ( length $jq_error_msg > $maxlen ) {
            my $substr_len = $maxlen - 5000;          # room for cmd
            my $cmd_err = join( "\n", @$full_buf );
            $cmd_err = substr( $cmd_err, length($cmd_err) - $substr_len,
                $substr_len );
            $jq_error_msg = join( "\n", $error_msg, $cmd_err );
        }

        $self->error_msg($jq_error_msg);
    }

    # since this can be a long-running process, ping the server
    # before we try and save.
    if ( !$self->db->dbh->ping ) {

        # Refresh db connection.
        $self->db->dbh(undef);
    }

    $self->save();

    if ( !$success ) {
        if ($debug) {
            warn "$cmd failed: " . $self->error_msg() . "\n";
        }
    }

    return $success;
}

sub lock {
    my $self     = shift;
    my %arg      = @_;
    my $hostname = $arg{hostname} || TQ::Config->get_hostname();

    # we lock-per-hostname
    # since we are potentially competing with N other job-running-hosts.
    # we leverage the row-locking behavior of the db and run an UPDATE
    # with an explicit WHERE for the host value so that we can trust
    # that our lock is exclusive to $hostname.
    my $dbh = $self->db->dbh;
    my $sql
        = qq/update job_queue set host=? where id=? and (host=? or host is null)/;
    my $updated = $dbh->do( $sql, undef, $hostname, $self->id, $hostname );
    if ( $updated == 0 or $updated == "0E0" ) {
        return 0;
    }
    else {
        $self->load;    # re-load
                        # sanity check
        if ( !$self->host or $self->host ne $hostname ) {
            return 0;
        }
    }

    # will be re-set by run(). this just flags as locked.
    $self->start_dtim( time() );
    $self->save();
    return 1;
}

sub get_queued {
    my $self = shift;    # object or class method
    my %arg  = @_;
    my $hostname = $arg{hostname} || TQ::Config->get_hostname();
    my $limit = $arg{limit} || $MAX_PER_QUEUE;
    if ( $limit =~ m/\D/ ) {
        confess "limit must be an integer";
    }
    my $queued = $self->fetch_all(
        query => [
            start_dtim    => undef,
            schedule_dtim => { le => [ undef, time() ] },
            or            => [ host => undef, host => $hostname ],
        ],
        sort_by => 'created_at ASC',
        limit   => $limit,
    );
    return $queued;
}

sub get_queued_with_locks {
    my $self   = shift;
    my %arg    = @_;
    my $limit  = $arg{limit} || $MAX_PER_QUEUE;
    my @locked = ();
LOOK: while ( @locked < $limit ) {
        my $queued = $self->get_queued(%arg);
        for my $job (@$queued) {
            if ( $job->lock(%arg) ) {
                push @locked, $job;
            }
        }
        if ( !@$queued ) {
            last LOOK;
        }
    }
    return \@locked;
}

sub get_locked {
    my $self   = shift;
    my $locked = $self->fetch_all(
        logic => 'AND',
        query => [
            '!start_dtim' => undef,    # is not null
            complete_dtim => undef,    # is null
            host => TQ::Config->get_hostname(),    # limit to this machine
        ],
        sort_by => 'created_at ASC'
    );
    return $locked;
}

sub is_locked {
    my $self = shift;
    if ( $self->start_dtim && !$self->complete_dtim ) {
        return 1;
    }
    else {
        return 0;
    }
}

1;
