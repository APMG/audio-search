use strict;
use warnings;

use TQApp;

my $app = TQApp->apply_default_middlewares(TQApp->psgi_app);
$app;

