#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use lib 'lib';

# test user class
{

    package MyTestUser;
    @MyTestUser::ISA = ('TQ::User');
    sub DESTROY { my $u = shift; $u->delete if $u->id; }
}

use_ok('TQ::User');

my $user_name  = 'iam-user';
my $user_pw    = 'secret';
my $user_email = 'iamuser@nosuchemail.org';

#$Rose::DB::Object::Debug = 1;
#$Rose::DB::Object::Manager::Debug = 1;

ok( my $user = MyTestUser->new(
        name  => $user_name,
        pw    => $user_pw,
        email => $user_email,
        )->save(),
    "new User"
);

ok( $user->check_password($user_pw), "check_password" );
