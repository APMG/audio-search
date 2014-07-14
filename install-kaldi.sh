#!/bin/bash -ex

#Dependencies: SVN

CHECKOUT_PATH=tools/kaldi-trunk

if [ ! -d $(dirname $0)/$CHECKOUT_PATH ]; then
  ( cd tools
  svn export -r 4038 https://svn.code.sf.net/p/kaldi/code/trunk kaldi-trunk )
  n=4    # number of cpus
  patch -p0 -i kaldi-build.diff
  ( cd $CHECKOUT_PATH/tools
  make -j $n
  cd openfst
  make
  make install )
  ( cd $CHECKOUT_PATH/src
  ./configure
  make depend
  make -j $n )
fi

if [ -d $CHECKOUT_PATH/egs/wsj/s5/steps ]; then
  rsync -a --exclude .svn $CHECKOUT_PATH/egs/wsj/s5/steps/ $(dirname $0)/steps
  rsync -a --exclude .svn $CHECKOUT_PATH/egs/wsj/s5/utils/ $(dirname $0)/utils
  rm -rf tools/kaldi-trunk/egs
else
  echo "It appears Kaldi could not be built. You will not be able to use the Kaldi decoder."
fi
