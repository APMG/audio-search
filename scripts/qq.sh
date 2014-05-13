# (C) 2010, 2011 Cantab Research Limited
# queue functions

# splits a dbl file into many in the given directory named dblPart$NUM
qqSplit() { 
  local QUIET=$SHELLOPTS && set +x
  local nmin=1
  local nmax=0

  if [ ! -z "$SGE_ROOT" ] ; then
    local npart=40  # splits into no more than this number of jobs
  else
    local npart=8   # EDIT THIS - assumes a quad core machine
  fi

  if [ $1 = '-npart' ] ; then
    npart=$2
    shift 2
  fi
    
  if [ $1 = '-nmin' ] ; then
    nmin=$2
    shift 2
  fi
    
  if [ $1 = '-nmax' ] ; then
    nmax=$2 ;
    shift 2
  fi

  local DBL=$1;
  local PREFIX=$2;
  local DIR=`dirname $PREFIX`
  
  local ntotal=`cat $DBL | wc -l`
  if [ $ntotal -eq 0 ] ; then
    echo "qqSplit: file empty: $DBL";
    exit 1
  fi

  if [ $nmax -gt 0 ] ; then
    npart=$(( (ntotal - 1) / nmax + 1 )) 
  fi

  if [ $(( ntotal / npart )) -lt $nmin ] ; then
    npart=$((( ntotal + nmin - 1 ) / nmin ))
  fi

  local n=0
  mkdir -p $DIR
  rm -f $PREFIX*
  xset=`echo $- | perl -pe 's/[^x]*//g'`
  set +x
  cat $DBL | while read line ; do
    echo $line >> $PREFIX$(( n % npart + 1 ))
    n=$((n + 1))
  done
  if [ ! -z $xset ] ; then set -x ; fi

  echo "npart=$npart" > $DIR/qq.cfg
  if [ ! $nmax -gt 0 ] ; then
    nmax=`wc $DBL | awk -v n="$npart" '{printf "%0.f", ($1/n)}'`
  fi
  echo "nmax=$nmax" >> $DIR/qq.cfg

  if echo $QUIET | egrep -q xtrace ; then set -x ; fi
}

# runs an array job specified on the command line
qqArray() {
  local QUIET=$SHELLOPTS && set +x

  if [ -z "$QQPRIORITY" ] ; then
    QQPRIORITY=0
  fi
  local OPTS="";
  local QARG="-q cpu.q"
  while [ "$(echo $1 | head -c 1)" = "-" ] ; do
    if [ $1 = '-q' ] ; then
      QARG="$1 $2"
      shift 2
    else
      local OPTS="$OPTS $1 $2"
      shift 2
    fi
  done
  local CMD=$1
  local DIR=$2
  local path=`echo $CMD | awk '{print $1}'`

  source $DIR/qq.cfg

  rm -f $DIR/qqArray.log*
  cat << EOF > $DIR/qqArray.sh
INIT=\`date +%s\`
$CMD >& $DIR/qqArray.log-\$SGE_TASK_ID
echo \`date +%s\` \$INIT - 1 + p | dc > $DIR/qqArray.time-\$SGE_TASK_ID
EOF
  chmod +x $DIR/qqArray.sh
  if [ ! -z "$SGE_ROOT" ] ; then
    qsub -p $QQPRIORITY $QARG $OPTS -terse -sync yes -cwd -j yes -r yes -o $DIR/qqArray.log -N `basename $path` -t 1-$npart $DIR/qqArray.sh | egrep -v "exited with exit code 0.$"
  else
    for(( n = 1; n <= $npart; n++)); do
      export SGE_TASK_ID=$n && bash -c $DIR/qqArray.sh &
    done
    wait
  fi

  for name in  $DIR/qqArray.log $DIR/qqArray.log-* ; do
    if [ -s $name  ] ; then
      echo ":::: LOG FILE :::: $name"
      cat $name
    fi
  done
 
  for(( n = 1; n <= $npart; n++)); do
    cat $DIR/qqArray.time-$n
  done | awk '{t += $1} END{print "time: " t}'

  if [ ! -z $nmax ] ; then
    for(( n = 1; n <= $npart; n++)); do
      cat $DIR/qqArray.time-$n
    done | awk -v "n=$npart" '{t += $1} END{if(t/n<300){print "WARNING: each item in job took less than suggested minimum time.\nCan you use a larger -nmax?"}else if(t/n>1800){print "WARNING: each item in job took longer than suggested maximum time.\nCan you use a smaller -nmax?"}}'
    for(( n = 1; n <= $npart; n++)); do
      cat $DIR/qqArray.time-$n
    done | awk -v "old=$nmax" -v "n=$npart" '{t += $1} END{printf "Note, each item in a job should run in 5-30mins, average item time: %0.2f mins, suggest -nmax %0.0f\n",t/(60*n),0.5+(old*750*n/t)}'
  fi
 
  find $DIR -name qqArray.sh\* -print0 -o -name qqArray.log\* -print0 -o -name qqArray.time\* -print0 | xargs -0 rm

  if echo $QUIET | egrep -q xtrace ; then set -x ; fi
}
