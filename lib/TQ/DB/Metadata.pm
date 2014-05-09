package TQ::DB::Metadata;
use strict;
use warnings;
use base 'Rose::DB::Object::Metadata';

# make default errors more verbose
sub init_error_mode { return 'confess' }

1;
