#!/bin/bash

PACKAGE=local-lib-2.000012
cd "$(dirname "$0")"

rm -fr ~/usr/local/tmp/$PACKAGE
mkdir -p ~/usr/local/tmp

tar xvf $PACKAGE.tar -C ~/usr/local/tmp
cd ~/usr/local/tmp/$PACKAGE
perl Makefile.PL --bootstrap=${1:-~/usr/local}
make test && make install


