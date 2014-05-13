package TQ::ScheduledJob;
use strict;
use warnings;
use base qw( TQ::DB );
use Carp;
use TQ::Config;
use UUID::Tiny ':std';

__PACKAGE__->meta->setup(
    table => 'scheduled_jobs',

    columns => [
        id   => { type => 'serial', not_null => 1 },
        uuid => { type => 'char',   length   => 36, not_null => 1 },
        status => {
            type     => 'character',
            length   => 1,
            not_null => 1,
            default  => 'A'
        },
        name        => { type => 'varchar',  length   => 255, },
        crontab     => { type => 'varchar',  length   => 255, },
        cmd         => { type => 'text',     length   => 65535 },
        description => { type => 'text',     length   => 65535, },
        created_by  => { type => 'integer',  not_null => 1 },
        updated_by  => { type => 'integer',  not_null => 1 },
        created_at  => { type => 'datetime', not_null => 1 },
        updated_at  => { type => 'datetime', not_null => 1 },
    ],

    primary_key_columns => ['id'],

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

    relationships => [

        queued => {
            class      => 'TQ::JobQueue',
            type       => 'one to many',
            column_map => { id => 'xid' },
            query_args => [
                type       => 'S',
                start_dtim => undef,
            ],
        },

        completed => {
            class      => 'TQ::JobQueue',
            type       => 'one to many',
            column_map => { id => 'xid' },
            query_args => [
                type             => 'S',
                '!complete_dtim' => undef,
            ],
        },

        running => {
            class      => 'TQ::JobQueue',
            type       => 'one to many',
            column_map => { id => 'xid' },
            query_args => [
                type            => 'S',
                '!start_dtim'   => undef,
                'complete_dtim' => undef,
            ],
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

1;
