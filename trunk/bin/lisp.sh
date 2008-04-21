#!/bin/bash

if [ "$1" == "" ]; then
    echo -n "Lisp name? [default=$$] "
    read name
    if [ "$name" == "" ]; then
        name=$$
    fi
else 
    name=$1
fi

pipe=$HOME/.lim_bridge_channel-${name}
echo -en "\033]2;Lisp at ~/.lim_bridge_channel-${name}\007"
echo -e "*** Lisp listener at $pipe\n"

PERL_RL=gnu $HOME/local/bin/vim-to-lisp-funnel.pl $pipe sbcl $*
