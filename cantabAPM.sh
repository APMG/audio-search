#!/bin/bash -ex

# Dependencies: Julius, CMUseg_0.5, sox.

PREFIX=$(dirname $0)
AMDIR=$PREFIX/etc/am 
LMBASE=$PREFIX/etc/lm/default
JCONF=$PREFIX/etc/mjulius.jconf

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
WORK=$PREFIX/tmp-$$

mkdir -p $WORK

# Runs CMUseg:
wavName=$(basename ${INPUT/%.wav})
echo $wavName | perl -pe "s:^:$WORK/tmp-rec/:" | perl -pe 's:^(.*)/.*$:$1:' | sort -u | xargs --no-run-if-empty mkdir -p

rm -f $WORK/splitFiles.dbl
$PREFIX/scripts/wav2pem $INPUT $WORK/tmp-rec/$wavName.pem $PREFIX/tools

cat $WORK/tmp-rec/$wavName.pem | egrep -v '^;;' | while read dummy chan spkr init quit cond ; do
  durn=`printf "%.2f" $(perl -e "print $quit-$init")`
  needSplit=$(awk 'BEGIN{ print ('$durn' > 45) }')
  if [ "$needSplit" -eq 1 ];then
    durn2=$(awk 'BEGIN{ print ('$durn' / 2) }')
    init2=$(awk 'BEGIN{ print ('$durn2' + '$init') }')
    wav1=$WORK/tmp-rec/$wavName-$init+$durn2.wav
    wav2=$WORK/tmp-rec/$wavName-$init2+$durn2.wav
    sox $INPUT $wav1 trim $init $durn2      
    sox $INPUT $wav2 trim $init2 $durn2
    echo $wavName-$init+$durn2 >> $WORK/splitFiles.dbl
    echo $wavName-$init2+$durn2 >> $WORK/splitFiles.dbl
  else
    wav=$WORK/tmp-rec/$wavName-$init+$durn.wav
    sox $INPUT $wav trim $init $durn
    echo $wavName-$init+$durn >> $WORK/splitFiles.dbl
  fi
done

# Runs Julius:
cat $WORK/splitFiles.dbl | perl -ne '{chomp; print "'$WORK'/tmp-rec/$_.wav\n"}' > $WORK/test.scp
$PREFIX/tools/julius-4.2.3/julius/julius -C $JCONF -bs 90.0 -walign -h $AMDIR/julius.mmf -hlist $AMDIR/julius.tie -input file -filelist $WORK/test.scp -v $LMBASE.dct -nlr $LMBASE.lm3 -htkconf $AMDIR/hcopy-mfcc2.cfg &> $WORK/log
cat $WORK/splitFiles.dbl | perl -ne '{chomp; print "'$WORK'/tmp-rec/$_\n"}' > $WORK/testSplit.dbl
$PREFIX/scripts/glueJulius.pl $WORK/testSplit.dbl $WORK/log | sed "s:"$WORK/tmp-rec/"::" | $PREFIX/scripts/mlf2json.py > $OUTPUT

rm -rf tmp-$$

exit 0
