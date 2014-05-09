package TQ::Media;
use strict;
use warnings;
use base qw( TQ::DB );
use Carp;
use Data::Dump qw( dump );
use UUID::Tiny ':std';

__PACKAGE__->meta->setup(
    table   => 'media',
    columns => [
        id         => { type => 'serial',  not_null => 1 },
        uuid       => { type => 'char',    length   => 36, not_null => 1 },
        name       => { type => 'varchar', length   => 255, },
        transcript => { type => 'text',    length   => 16_777_215 },
        uri        => { type => 'text',    length   => 65535 },
        status => {
            type     => 'char',
            length   => 1,
            default  => 'A',
            not_null => 1,
        },
        user_id    => { type => 'integer',  not_null => 1, },
        created_by => { type => 'integer',  not_null => 1 },
        updated_by => { type => 'integer',  not_null => 1 },
        created_at => { type => 'datetime', not_null => 1 },
        updated_at => { type => 'datetime', not_null => 1 },
    ],
    primary_key_columns => ['id'],
    unique_keys         => ['uuid'],
    foreign_keys        => [
        created_user => {
            class       => 'TQ::User',
            key_columns => { created_by => 'id' },
        },
        updated_user => {
            class       => 'TQ::User',
            key_columns => { updated_by => 'id' },
        },
        owner => {
            class       => 'TQ::User',
            key_columns => { 'user_id' => 'id' },
        },
    ],

);

sub insert {
    my $self = shift;
    $self->uuid( lc( create_uuid_as_string(UUID_V4) ) ) unless $self->uuid;
    $self->SUPER::insert();
}

1;
