use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../../lib";

use TQApp;

my $app = TQApp->apply_default_middlewares(TQApp->psgi_app);
$app;

