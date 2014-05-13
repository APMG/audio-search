package TQ::User;
use strict;
use base qw( TQ::DB );
use Carp;
use Data::Dump qw( dump );
use UUID::Tiny ':std';

__PACKAGE__->meta->setup(
    table => 'users',

    columns => [
        id      => { type => 'serial',  not_null => 1 },
        guid    => { type => 'char',    length   => 16, not_null => 1 },
        pw      => { type => 'char',    length   => 64, not_null => 1 },
        api_key => { type => 'char',    length   => 36, not_null => 1, },
        name    => { type => 'varchar', length   => 255, not_null => 1 },
        email => {
            type     => 'varchar',
            length   => 255,
            not_null => 1,

            # force all email values to be lowercased
            'on_set' => sub { $_[0]->email( lc( $_[0]->email ) ) },
        },
        description => { type => 'text',     length   => 65535 },
        created_by  => { type => 'integer',  not_null => 1 },
        updated_by  => { type => 'integer',  not_null => 1 },
        created_at  => { type => 'datetime', not_null => 1 },
        updated_at  => { type => 'datetime', not_null => 1 },
    ],

    primary_key_columns => ['id'],

    unique_keys => [ ['guid'], ['email'] ],

    alias_column => [qw( pw local_password )],

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
        media => {
            class      => 'TQ::Media',
            column_map => { id => 'user_id' },
            type       => 'one to many',
        },
        jobs => {
            class      => 'TQ::JobQueue',
            column_map => { id => 'xid' },
            type       => 'one to many',
            query_args => [ type => 'U' ],
        },
    ],
);

sub apply_defaults {
    my $self = shift;
    if ( !$self->api_key ) {
        $self->api_key( lc( create_uuid_as_string(UUID_V4) ) );
    }
    $self->SUPER::apply_defaults(@_);
}

sub check_password {
    my $self = shift;
    my $pass = shift;
    return $self->local_password eq $self->encrypt($pass);
}

sub encrypt {
    return TQ::Utils::encrypt( pop(@_) );
}

sub looks_encrypted {
    my $self = shift;
    my $val = shift || $self->local_password;
    if ( length($val) == 64 && $val =~ m/^[a-z0-9\+]+$/ ) {

        #carp "$val looks encrypted";
        return 1;
    }
    return 0;
}

sub pw {
    my $self = shift;
    if (@_) {
        unless ( $self->looks_encrypted( $_[0] ) ) {
            $self->local_password( $self->encrypt( $_[0] ) );
        }
        else {
            $self->local_password( $_[0] );
        }
    }
    return $self->local_password;
}

1;
