package TQ::JobQueue;
use strict;
use warnings;
use base qw( TQ::DB );
use Carp;
use IPC::Cmd ();
use TQ::Config;
use UUID::Tiny ':std';

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
    my $self    = shift;
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
    $self->host( TQ::Config->get_hostname() );
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
    my $self = shift;
    if ( $self->is_locked ) {
        croak sprintf( "job %s is already locked", $self->id );
    }
    $self->start_dtim( time() );
    $self->save();
}

sub get_queued {
    my $self = shift;          # object or class method
    my $limit = shift || 10;
    if ( $limit =~ m/\D/ ) {
        confess "limit must be an integer";
    }
    my $queued = $self->fetch_all(
        query => [
            start_dtim    => undef,
            schedule_dtim => { le => [ undef, time() ] }
        ],
        sort_by => 'created_at ASC',
        limit   => $limit,
    );
    return $queued;
}

sub get_queued_with_locks {
    my $self = shift;

    # TODO race condition here if we ran multiple processes
    # simultaneously, since between fetch and lock another fetch
    # could happen.
    my $queued = $self->get_queued(@_);
    for my $job (@$queued) {
        $job->lock();
    }
    return $queued;
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
