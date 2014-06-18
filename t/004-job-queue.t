#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 26;
use lib 'lib';
use TQ::Config;
use TQ::JobQueue;
use Parallel::Forker;

SKIP: {

    if ( !$ENV{TQ_TEST_JOB_QUEUE} ) {
        skip "set TQ_TEST_JOB_QUEUE to test job_queue features", 13;
    }

    $ENV{TQ_USE_MASTER} = 1;    # force mysql master

    my $tmp_file = "/tmp/tq-job-queue-test";

    # setup
    if ( -e $tmp_file ) {
        diag("Removing old temp file $tmp_file");
        unlink($tmp_file) or die "can't unlink $tmp_file: $!";
    }

    # TODO this whole series could fail if we are using a live db
    my $old = TQ::JobQueue->get_locked();
    if (@$old) {
        for my $job (@$old) {
            diag( "Deleting (old) locked job " . $job->id );
            $job->delete();
        }
    }

    # create dummy job
    my $job = TQ::JobQueue->new( 'cmd' => "job-queue-test > $tmp_file" );
    $job->save();

    # TODO this whole series could fail if we are using a live db
    my $locked = TQ::JobQueue->get_locked();
    ok( !scalar(@$locked), "no locked jobs in queue" );

    ok( my $queued = TQ::JobQueue->get_queued_with_locks(),
        "get queued with locks" );
    is( scalar(@$queued), 1, "one queued job" );
    ok( $queued->[0]->is_locked, "queued job has lock" );

    for my $j (@$queued) {
        if ( !$j->run() ) {
            fail( "Job: " . $j->id );
        }
        else {
            pass( "Job ran: " . $j->pid );
        }
    }

    ok( -s $tmp_file, "$tmp_file exists (job ran successfully)" );

    # cleanup
    unlink($tmp_file);
    $job->delete();

    # start_after
    $job = TQ::JobQueue->add_job( "job-queue-test > $tmp_file", time() + 2 );
    $locked = TQ::JobQueue->get_locked();
    ok( !scalar(@$locked), "no locked jobs in queue" );

    ok( $queued = TQ::JobQueue->get_queued_with_locks(),
        "get queued with locks" );
    is( scalar(@$queued), 0, "zero queued jobs" );

    diag("sleeping 3 seconds to let schedule_dtim elapse");
    sleep(3);

    ok( $queued = TQ::JobQueue->get_queued_with_locks(),
        "get queued with locks" );
    is( scalar(@$queued), 1, "zero queued jobs" );

    for my $j (@$queued) {
        if ( !$j->run() ) {
            fail( "Job: " . $j->id );
        }
        else {
            pass( "Job ran: " . $j->pid );
        }
    }

    ok( -s $tmp_file, "$tmp_file exists (job ran successfully)" );

    # cleanup
    unlink($tmp_file);
    $job->delete();
}

SKIP: {

    if ( !$ENV{TQ_TEST_JOB_QUEUE} ) {
        skip "set TQ_TEST_JOB_QUEUE to test job_queue features", 13;
    }

    # test race condition bug.
    # fork N+1 kids who all try and compete for the (smaller) pool
    # of jobs.
    my $N      = 100;
    my $tmpdir = Path::Class::Dir->new('/tmp/tq-job-queue-fork-test');
    $tmpdir->mkpath(1);

    # queue N jobs (one less than kids)
    my @jobs;
    for my $i ( 1 .. $N ) {
        my $job = TQ::JobQueue->new( 'cmd' => "job-queue-test > $tmpdir/$i" );
        $job->save;
        push @jobs, $job;
    }

    # no jobs running
    my $locked = TQ::JobQueue->get_locked();
    ok( !scalar(@$locked), "no locked jobs in queue" );

    # set up forker
    # set up the parallel manager
    my $manager = Parallel::Forker->new( use_sig_child => 1 );

    # signal handling (propagate death)
    $SIG{CHLD} = sub { Parallel::Forker::sig_child($manager) };
    $SIG{TERM} = sub {
        if ( $manager && $manager->in_parent ) {
            $manager->kill_tree_all('TERM');
            die "Quitting...\n";
        }
    };

    # mimic unique hosts when we fork kids
WORKER: for my $worker_n ( ( 1 .. ( $N + 1 ) ) ) {
        my $process = $manager->schedule(
            name         => $worker_n,    # unique
            run_on_start => sub {
                my $proc = shift;
                diag( sprintf "starting worker %s\n", $proc->name );
                my $mock_host = 'worker-' . $worker_n;
                my $queued    = TQ::JobQueue->get_queued_with_locks(
                    hostname => $mock_host,
                    limit    => 1,
                );
                for my $job (@$queued) {
                    diag(
                        sprintf(
                            "job %s queued for host %s running on %s",
                            $job->id, $job->host, $mock_host
                        )
                    );
                    $job->run( hostname => $mock_host );
                }
            },
            run_on_finish => sub {
                my ( $proc, $exit_status ) = @_;
                diag( sprintf "worker %s exited with %s\n",
                    $proc->name, $exit_status );
            },
        );
        $process->ready();
    }

    $manager->poll();        # start ready workers
    $manager->wait_all();    # block till we're done

    # make sure we have $N files
    my $count = 0;
    while ( my $file = $tmpdir->next ) {
        next unless $file->basename =~ m/^\d+$/;
        diag($file);
        $count++;
        $file->remove();
    }

    is( $count, $N, "got expected job outputs" );

    for my $job (@jobs) {
        $job->delete();
    }

}

