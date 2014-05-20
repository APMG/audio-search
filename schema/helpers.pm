package schema::helpers;
use strict;
use warnings;
use lib 'lib';
use Carp;
use TQ::DBManager;
use TQ::DB;
use TQ::Config;
use Data::Dump qw( dump );
use Rose::DB::Object;
use Rose::DB::Object::Metadata;
use SQL::SplitStatement;

$ENV{TQ_USE_MASTER} = 1;

# singleton db connection
our $db = TQ::DBManager->new_or_cached();

sub table_class {
    my $table = shift or croak "table name required";
    my $class = shift or croak "class name required";

    {
        no strict 'refs';
        @{ $class . '::ISA' } = ('TQ::DB');
    }

    my $meta = Rose::DB::Object::Metadata->new(
        table => $table,
        class => $class,
    );
    $meta->auto_initialize();

    return $meta;

}

sub has_column {
    my $table_or_meta = shift or croak "table_name or meta object required";
    my $column        = shift or croak "column name required";

    my $meta;
    if ( !ref $table_or_meta ) {
        $meta = table_class( $table_or_meta, $table_or_meta . 'Class' );
    }
    else {
        $meta = $table_or_meta;
    }

    for my $col ( @{ $meta->columns } ) {
        if ( $col->name eq $column ) {
            return 1;
        }
    }
    return 0;
}

sub table_exists {
    my $table = shift or croak "table name required";
    my $meta;
    eval { $meta = table_class( $table, $table ); };
    if ( $@ or !$meta ) {
        if ( $@ !~ m/Could not auto-generate columns for class/ ) {
            warn $@;
        }
        return 0;
    }
    return $meta;
}

sub read_tq_ddl {
    my $sql_file   = TQ::Config->get_app_root->file('etc/tq.sql');
    my $sql        = $sql_file->slurp;
    my $splitter   = SQL::SplitStatement->new();
    my @statements = $splitter->split($sql);
    return \@statements;
}

sub create_table {
    my $table_name = shift or croak "table name required";
    my $statements = read_tq_ddl();
    my $statement;
    for my $s (@$statements) {
        if ( $s =~ m/create table if not exists `?$table_name`?\s/ ) {
            $statement = $s;
            last;
        }
    }
    if ( !$statement ) {
        croak "No create statement found for $table_name";
    }
    return $db->dbh->do($statement);
}

sub get_index_defs {
    my $table_name = shift or croak "table name required";
    my $col_name   = shift or croak "column name required";

    my $sth = $db->dbh->prepare("show indexes from $table_name");
    $sth->execute;
    my $out = $sth->fetchall_hashref( [qw( Key_name Seq_in_index )] );

    #warn dump $out;
    my @defs;
    for my $key_name ( keys %$out ) {
        for my $seq ( keys %{ $out->{$key_name} } ) {
            if ( $out->{$key_name}->{$seq}->{Column_name} eq $col_name ) {
                push @defs, $key_name;
            }
        }
    }
    return [ \@defs, $out ];
}

sub get_table_def {
    my $table_name = shift or croak "table name required";
    
    my $sth = $db->dbh->prepare("show create table $table_name");
    $sth->execute;
    my $out = $sth->fetchall_arrayref();
    return $out->[0]->[1];
}

1;
