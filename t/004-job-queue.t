#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 13;
use lib 'lib';
use TQ::Config;
use TQ::JobQueue;

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
