#!/usr/bin/perl -w

# take a list of split MLF files from stdin in random order
# and glue them back together in order specified.

$scale = 10000000;

open(DBL, $ARGV[0]) || die "did't open $ARGV[0]\n";

$keep = $/;
undef $/;
open(MLF, $ARGV[1]) || die "did't open $ARGV[1]\n";
$mlf = <MLF>;
close(MLF);
$/ = $keep;

while($mlf =~ m/input speechfile: (.*?)\.wav\n.*?\n ----------------------------------------\n(.*?\n)re-computed AM score:/gs) {
  $hash{$1} = $2;
  #print "$1\n";
  #print "$2\n";
}

print "#!MLF!#\n";
undef $base;
while($dbl = <DBL>) {
  chomp $dbl;
  $dbl =~ m/^(.*)-(\d+\.\d+)\+\d+\.\d+$/;
  $stem = $1;
  $offset = $2;
  if(!defined($base) || $base ne $stem) {
    if(defined($base)) {
      print ".\n";
    }
    print "\"$stem.rec\"\n";
  }
  # while($hash{$dbl} =~ m/\[ *(\d+) +(\d+)\] +.*? +(.*?) +\[.*?\]/gs) {
  # while($hash{$dbl} =~ m/\[ *(\d+) +(\d+)\].*? +(.*?) +\[/gs) {
  while($hash{$dbl} =~ m/\[ *(\d+) +(\d+)\].*? +(.*?)  (.*?)\t/gs) {
    $init = $scale * ($offset + 0.01 * $1);
    $quit = $scale * ($offset + 0.01 * ($2 + 1));
    print "$init\t$quit\t$4\n";
  }

  $base = $stem;
}
print ".\n";

exit 0;
