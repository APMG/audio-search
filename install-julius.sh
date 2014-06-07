#!/bin/bash -e

WPAIR=false           # For better accuracy, set this to be true, set WPAIR=true in cantabAPM.sh - runs much slower.
mkdir -p tools
cd $(dirname $0)
if [ ! -d $(dirname $0)/tools/julius-4.3.1 ]; then
  (cd tools
  wget -O - 'sourceforge.jp/frs/redir.php?m=jaist&f=%2Fjulius%2F60273%2Fjulius-4.3.1.tar.gz' | tar xfz -
  cd julius-4.3.1
  if $WPAIR; then
    ./configure --enable-setup=standard --enable-wpair --enable-wpair-nlimit --enable-word-graph --with-mictype=oss --prefix=$PWD
  else
    ./configure --enable-setup=standard --enable-word-graph --with-mictype=oss --prefix=$PWD
  fi
  make all
  make install)
fi

