#!/bin/bash

fail() {
    echo $*
    exit 1
}

if [[ "$1" == "" ]]; then
    fail "Must specify the name of the tag."
fi

TAG=$1

if [[ ! -d "tag/$TAG" ]]; then
    # not there, try svn up-ing it first.
    echo "Checking out $TAG"
    svn up tag/$TAG > /dev/null
    if [[ "$?" -gt 0 ]]; then
        fail "Invalid tag name, or connection error."
    fi
fi
PACKAGE=lim-$TAG
rm -rf $PACKAGE

cd tag
cp -r $TAG $PACKAGE
echo "Removing Subversion files."
find $PACKAGE -name .svn -type d -exec rm -rf "{}" 2> /dev/null \; 
echo "Packing..."
tar czf ${PACKAGE}.tar.gz $PACKAGE
rm -rf $PACKAGE
mv ${PACKAGE}.tar.gz ..
echo "Packaged $TAG in ${PACKAGE}.tar.gz"

