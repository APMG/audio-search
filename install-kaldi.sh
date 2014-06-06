#!/bin/bash -ex

#Dependencies: SVN

if [ ! -d $(dirname $0)/tools/kaldi-trunk ]; then
  ( cd tools
  svn export -r 4038 https://svn.code.sf.net/p/kaldi/code/trunk kaldi-trunk )
  n=4    # number of cpus
  ( cd tools/kaldi-trunk/tools
  make -j $n )
  ( cd tools/kaldi-trunk/src
  ./configure
  make depend
  make -j $n )
fi

cp -pr tools/kaldi-trunk/egs/wsj/s5/steps $(dirname $0)/steps
cp -pr tools/kaldi-trunk/egs/wsj/s5/utils $(dirname $0)/utils

rm -rf tools/kaldi-trunk/egs
