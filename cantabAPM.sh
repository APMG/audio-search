#!/bin/bash -e

set -x

# Written by Cantab Research Ltd for use by American Public Media (APM), May 2014.
# Dependencies: Julius, CMUseg_0.5, sox, ffmpeg.

PREFIX=$(dirname $0)
AMDIR=$PREFIX/etc/am 
LMBASE=$PREFIX/etc/lm/default
JCONF=$PREFIX/etc/mjulius.jconf
TMPDIR=/var/extra/audio/work
QUEUE=true
WPAIR=false       # For improvement in accuracy, configure Julius with WPAIR=true (in install.sh) and set this to be true - runs much slower.
BEAM=80.0         # Can be increased for improvement in accuracy.

if [ $# -ne 2 ] ; then
  echo "syntax: recognizeAPM.sh <wavFile> <outputFile>" 
  exit 1
fi

if [ ! -f "$1" ] ; then
  echo "Can't find input .wav file"
  exit 1
fi

INPUT=$1
OUTPUT=$2
wavName=$(basename ${INPUT/%.wav})
WORK=$TMPDIR/audio-tmp-$wavName-$$

mkdir -p $WORK

# Runs CMUseg:
echo "Running audio segmentation"
#ffmpeg -i "$INPUT" -ar 16000 -ac 1 $WORK/$wavName.wav < /dev/null 2> /dev/null
#sox $INPUT -r 16k $WORK/$wavName.wav
cp $INPUT $WORK/$wavName.wav
echo $wavName | perl -pe "s:^:$WORK/tmp-rec/:" | perl -pe 's:^(.*)/.*$:$1:' | sort -u | xargs --no-run-if-empty mkdir -p

rm -f $WORK/splitFiles.dbl
$PREFIX/scripts/wav2pem $WORK/$wavName.wav $WORK/tmp-rec/$wavName.pem $PREFIX/tools

cat $WORK/tmp-rec/$wavName.pem | egrep -v '^;;' | while read dummy chan spkr init quit cond ; do
  durn=`printf "%.2f" $(perl -e "print $quit-$init")`
  needSplit=$(awk 'BEGIN{ print ('$durn' > 45) }')
  if [ "$needSplit" -eq 1 ];then
    durn2=$(awk 'BEGIN{ print ('$durn' / 2) }')
    init2=$(awk 'BEGIN{ print ('$durn2' + '$init') }')
    wav1=$WORK/tmp-rec/$wavName-$init+$durn2.wav
    wav2=$WORK/tmp-rec/$wavName-$init2+$durn2.wav
    sox $WORK/$wavName.wav $wav1 trim $init $durn2      
    sox $WORK/$wavName.wav $wav2 trim $init2 $durn2
    echo $wavName-$init+$durn2 >> $WORK/splitFiles.dbl
    echo $wavName-$init2+$durn2 >> $WORK/splitFiles.dbl
  else
    wav=$WORK/tmp-rec/$wavName-$init+$durn.wav
    sox $WORK/$wavName.wav $wav trim $init $durn
    echo $wavName-$init+$durn >> $WORK/splitFiles.dbl
  fi
done

# Runs Julius:
echo "Running Julius decoder"
cat $WORK/splitFiles.dbl | perl -ne '{chomp; print "'$WORK'/tmp-rec/$_.wav\n"}' > $WORK/test.scp

if $QUEUE; then
  source $PREFIX/scripts/qq.sh
  qqSplit $WORK/test.scp $WORK/tmp/scp
  if $WPAIR; then
    qqArray "$PREFIX/tools/julius-4.3.1/julius/julius -C $JCONF -bs $BEAM -walign -h $AMDIR/juliusBin.mmf -hlist $AMDIR/julius.tie -input file -filelist $WORK/tmp/scp\$SGE_TASK_ID -v $LMBASE.dct -d $LMBASE.bin -lmp 13.0 0.0 -lmp2 13.0 0.0 -nlimit 8 -htkconf $AMDIR/hcopy-mfcc2.cfg " $WORK/tmp &> $WORK/log
  else
    qqArray "$PREFIX/tools/julius-4.3.1/julius/julius -C $JCONF -bs $BEAM -walign -h $AMDIR/juliusBin.mmf -hlist $AMDIR/julius.tie -input file -filelist $WORK/tmp/scp\$SGE_TASK_ID -v $LMBASE.dct -d $LMBASE.bin -lmp 13.0 0.0 -lmp2 13.0 0.0 -htkconf $AMDIR/hcopy-mfcc2.cfg " $WORK/tmp &> $WORK/log
  fi
else
  if [ ! $WPAIR ]; then
    $PREFIX/tools/julius-4.3.1/julius/julius -C $JCONF -bs $BEAM -walign -h $AMDIR/juliusBin.mmf -hlist $AMDIR/julius.tie -input file -filelist $WORK/test.scp -v $LMBASE.dct -d $LMBASE.bin -nlimit 8 -htkconf $AMDIR/hcopy-mfcc2.cfg &> $WORK/log
  else
    $PREFIX/tools/julius-4.3.1/julius/julius -C $JCONF -bs $BEAM -walign -h $AMDIR/juliusBin.mmf -hlist $AMDIR/julius.tie -input file -filelist $WORK/test.scp -v $LMBASE.dct -d $LMBASE.bin -htkconf $AMDIR/hcopy-mfcc2.cfg &> $WORK/log
  fi
fi

echo "Writing JSON output"
cat $WORK/splitFiles.dbl | perl -ne '{chomp; print "'$WORK'/tmp-rec/$_\n"}' > $WORK/testSplit.dbl
$PREFIX/scripts/glueJulius.pl $WORK/testSplit.dbl $WORK/log | sed "s:"$WORK/tmp-rec/"::" | $PREFIX/scripts/mlf2json.py > $OUTPUT

rm -rf $WORK
echo "Done"

exit 0
