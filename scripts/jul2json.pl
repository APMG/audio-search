#!/usr/bin/perl -w

# take a list of split MLF files from stdin in random order
# and glue them back together in order specified.

#$scale = 10000000;

open(DBL, $ARGV[0]) || die "did't open $ARGV[0]\n";
$keep = $/;
undef $/;
open(MLF, $ARGV[1]) || die "did't open $ARGV[1]\n";
$mlf = <MLF>;
close(MLF);
$/ = $keep;

while($mlf =~ m/input speechfile: (.*?)\.wav\n(.*?)\ncmscore1: (.*?)\n.*? ----------------------------------------\n(.*?\n)re-computed AM score:/gs) {
  $hash{$1} = $4;
  $confidences{$1} = $3; 
  $misc{$1} = $2;
}
print "{\n  \"words\": [\n";
undef $base;
$p = 1;
while($dbl = <DBL>) {    
  chomp $dbl;
  $dbl =~ m/^(.*)-(\d+\.\d+)\+\d+\.\d+$/;
  $stem = $1;
  $offset = $2;

  @conf = split(/ /, $confidences{$dbl});
  if ($misc{$dbl} =~ /00 _default: got no candidates, output 1st pass result as a final result/) {
    s/0.000/undefined/ for @conf;
  } 
  $n=0;
  while($hash{$dbl} =~ m/\[ *(\d+) +(\d+)\].*? +(.*?)  (.*?)\t/gs) {
    $init = ($offset + 0.01 * $1);
    $quit = ($offset + 0.01 * ($2 + 1));
    $dur = ($quit - $init);
    print "      \"time\": \"$init\",\n";
    printf "      \"duration\": \"%6.2f\",\n", $dur;
    print "      \"word\": \"$4\",\n"  ;
    print "      \"confidence\": \"$conf[$n]\"\n" ;
    if (($n == @conf-1) && ($p == (keys %hash))) {
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
