package TQ::DB;
use strict;
use warnings;
use base qw(
    Rose::DB::Object
    Rose::DB::Object::Helpers
    Rose::DBx::Object::MoreHelpers
);
use MRO::Compat;
use mro 'c3';

use Carp;
use Data::Dump qw( dump );
use Search::Tools::UTF8;

use TQ::DBManager;
use TQ::DB::Metadata;
use TQ::Utils;
use TQ::Config;
use DateTime;

sub meta_class { return 'TQ::DB::Metadata' }

sub init_db {
    my $self = shift;
    my $db   = TQ::DBManager->new_or_cached();
    return $db;
}

my $current_user;

sub current_user {
    my $class = shift;
    return $current_user if defined $current_user;
    my $user;
    my @usernames
        = ( $ENV{TQ_USER}, $ENV{REMOTE_USER}, $ENV{USER},
        'systemuser123456' );
    for my $u (@usernames) {
        if ( defined $u ) {
            for my $field (qw( guid email )) {

                #$class->db->logger("$field => $u");
                $user = TQ::User->new( $field => $u );
                $user->load_speculative;
                if ( $user->id ) {
                    $current_user = $user;
                    return $user;
                }
            }
        }
    }
    confess "Could not find a current owner";
}

sub set_current_user {
    my $class = shift;
    $current_user = shift;
}

sub set_admin_update {
    my $self = shift;
    my $flag = shift || 0;
    $self->{__barn_admin_update} = $flag;
}

sub delete {
    my $self = shift;
    $self->db( $self->db->get_write_handle() );
    return $self->SUPER::delete(@_);
}

sub insert {
    my $self = shift;
    $self->apply_defaults(1);
    $self->db( $self->db->get_write_handle() );
    return $self->SUPER::insert(@_);
}

sub update {
    my $self = shift;
    my %arg  = @_;
    $arg{changes_only} = 1;
    $self->apply_defaults;
    $self->db( $self->db->get_write_handle() );
    $self->SUPER::update(%arg);
}

sub save {
    my $self = shift;
    $self->db( $self->db->get_write_handle() );
    return $self->SUPER::save(@_);
}

sub apply_defaults {
    my $self = shift;
    if ( $self->{__barn_admin_update} ) {
        return $self;    # do not set values
    }
    my $is_new = shift;
    my $now    = DateTime->now()->set_time_zone( TQ::Config->get_tz() );
    my $user   = $self->current_user;
    for my $column ( $self->meta->columns ) {
        my $name       = $column->name;
        my $set_method = $column->mutator_method_name;
        my $get_method = $column->accessor_method_name;

        # allow to be already set
        if (    defined $self->$get_method
            and length $self->$get_method
            and $self->$get_method =~ /\S/
            and $set_method !~ /updated_/ )
        {
            next;
        }

        # defaults
        if ( $is_new && $name eq 'created_at' ) {
            $self->$set_method($now);
        }
        if ( $is_new && $name eq 'created_by' ) {
            $self->$set_method( $user->id );
        }
        if ( $name eq 'updated_at' ) {
            $self->$set_method($now);
        }
        if ( $name eq 'updated_by' ) {
            $self->$set_method( $user->id );
        }
        if ( $is_new && $name eq 'guid' ) {
            $self->$set_method( lc( TQ::Utils::random_str(16) ) );
        }
    }

    return $self;
}

sub __get_cre_user_column {
    my $self = shift;
    for my $column ( $self->meta->columns ) {
        my $name   = $column->name;
        my $method = $column->accessor_method_name;
        if ( $name eq 'created_by' ) {
            return $method;
        }
    }
    return;
}

sub __set_cre_user_column {
    my $self = shift;
    for my $column ( $self->meta->columns ) {
        my $name   = $column->name;
        my $method = $column->mutator_method_name;
        if ( $name eq 'created_by' ) {
            return $method;
        }
    }
    return;
}

1;
