#!/bin/bash

pos=$(expr index $STY .)
id=${STY:0:$pos-1}
name=${STY:$pos+13}

# aha, clever!
screen -x $STY -p 0 -X eval "hardstatus alwayslastline \"%{= bW}Lim $1%35= Steel Bank Common Lisp %= $name ($id)\""
rlwrap -b $BREAK_CHARS sbcl
