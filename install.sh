#!/bin/bash
VERSION=0.3.4
BASE=/usr/local/limp
LISP_FTP=$HOME/.vim/ftplugin/lisp


if [[ ! -d "$BASE" ]]; then
    mkdir -p $BASE
    if [[ $? -gt 0 ]]; then
        echo
        echo "ERROR: Failed creating installation directory. Forgot 'sudo'?"
        exit 1
    fi
else
    rm -rf $BASE/$VERSION
    rm $BASE/latest
fi

echo "Installing Limp $VERSION to $BASE/$VERSION..."

cp -fr $VERSION $BASE

echo "* symlink $BASE/$VERSION -> $BASE/latest"

ln -sf $VERSION $BASE/latest

if [[ ! -d "$LISP_FTP" ]]; then
    mkdir -p $LISP_FTP
fi

echo "* symlink $LISP_FTP -> $BASE/latest"

rm $LISP_FTP/limp
ln -sf $BASE/latest/vim $LISP_FTP/limp
ln -sf limp/limp.vim $LISP_FTP/limp.vim

echo "* generating Lisp thesaurus..."

cd $BASE/$VERSION/bin
./make-thesaurus.sh

echo "Done."

