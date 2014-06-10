#!/usr/bin/perl -w

# take a list of split MLF files from stdin in random order
# and glue them back together in order specified.
# For a single file.

$scale = 10000000;

open(DBL, $ARGV[0]) || die "did't open $ARGV[0]\n";
$keep = $/;
undef $/;
open(MLF, $ARGV[1]) || die "did't open $ARGV[1]\n";
$mlf = <MLF>;
close(MLF);
$/ = $keep;

while($mlf =~ m/\"(.*?)\.rec\"\n(.*?)\n.\n/gs) {
  $hash{$1} = $2;
}
print "{\n  \"words\": [\n";
undef $base;
$p = 1;
while($dbl = <DBL>) {    
  chomp $dbl;
  $dbl =~ m/^(.*)-(\d+\.\d+)\+\d+\.\d+$/;
  $stem = $1;
  $offset = $2;
  $n=0;
  while($hash{$dbl} =~ m/(\d+)\s*(\d+)\s(.*?)\n/gs) {
    $init = $offset + ($1/$scale);
    $dur = ($2/$scale);
    $word = $3;
    print "    {\n";
    print "      \"time\": \"$init\",\n";
    printf "      \"duration\": \"%.2f\",\n",$dur;
    print "      \"word\": \"$word\"\n";
    if (($n == $hash{$dbl} =~ tr/\n// - 1) && ($p == (keys %hash))) {
      print "    }\n";
    } else {
      print "    },\n";
    }
    $n = $n + 1;
  }
    $p = $p + 1;
  $base = $stem;
}
print "  ]\n}";
exit 0;
