#!/bin/bash

VERSION=0.3.4
PACKAGE=limp-$VERSION
INSTALL=$PACKAGE/$VERSION

mkdir -p $INSTALL
mkdir $INSTALL/docs

echo "Generating documentation..."
cd docs && rst2html.py index.txt index.html; cd ..

echo "Copying..."
cp -r docs/{index.html,screenshots,*png} $INSTALL/docs
cp -r bin vim $INSTALL

cp -r install.sh $PACKAGE

echo "Removing Subversion files."
find $PACKAGE -name .svn -type d -exec rm -rf "{}" 2> /dev/null \; 

echo "Packing..."
tar czf ${PACKAGE}.tar.gz $PACKAGE
rm -rf $PACKAGE
mv ${PACKAGE}.tar.gz ..
echo "Packaged $VERSION in ${PACKAGE}.tar.gz"

