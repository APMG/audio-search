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

if [ ! -d $(dirname $0)/tools/CMUseg_0.5 ]; then
  (cd tools
  wget -O - ftp://jaguar.ncsl.nist.gov/pub/CMUseg_0.5.tar.gz | tar xfz -
  sed -i 's/extern\ char\ \*sys\_errlist\[\]\;/\/\/extern\ char\ \*sys\_errlist\[\]\;\n\#include\ \<errno\.h\>\n/' CMUseg_0.5/src/lib/sphere/src/lib/sp/exit.c
  mkdir -p CMUseg_0.5/src/lib/sphere/bin
  unset CDPATH
  export arch=linux
  (cd CMUseg_0.5/src/lib/sphere && echo 10 | sh src/scripts/install.sh )
  mv CMUseg_0.5/src/lib/sphere/lib/*.a CMUseg_0.5/src/lib/sphere/lib/linux/
  sed -i "s/case\ NULL\:/case\ \'\\\0'\:/" CMUseg_0.5/src/UTT_gauss_class/main.c
  mv CMUseg_0.5/bin/linux CMUseg_0.5/bin/linux-orig
  mkdir CMUseg_0.5/bin/linux
  (cd CMUseg_0.5/src && make && make install))
fi
