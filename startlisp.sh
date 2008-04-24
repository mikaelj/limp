#!/bin/bash

#
# lisp.sh
#
# Boot a new Lisp, or attach to an existing.
#

#
# KNOWN ISSUES:
#
# * Doesn't clean up after itself (screenrc file).
#

progname=lisp.sh
version=$Revision$

print_version() {
    echo "$progname $version."
}

print_help() {
    cat <<EOF

Usage: $progname [options] [name-or-PID]
Connects to the Lisp specified by name-or-PID, or boot a new called 'name'.

Options:
  -h, --help            Print help (this text) and exit
  -v, --version         Print version information and exit
  -b, --boot[=path]     Boot a fresh Lisp, optionally using the core in <path>
  -l, --list            Display running Lisps

  Name must be unique! (But isn't currently enforced.)

Examples:
  # connect to a running Lisp named mylisp
  $progname mylisp

  # boot a new Lisp; name is automatically generated if not given
  $progname -b/path/to/my/huge-app.core
EOF
}
list_running_lisps() {
    echo "Currently running Lisps:"
    screen -ls | sed -ne 's/[^0-9]\+\([0-9]\+\)\.lim_listener-\([a-z]\+\).*/  \2 (\1)/p' | sort -k1,1
}

SHORTOPTS="hvb::lpP:"
LONGOPTS="help,version,boot::,list,private-do-boot,private-lim-screenrc:"

OPTS=$(getopt -o $SHORTOPTS --long $LONGOPTS -n "$progname" -- "$@")
eval set -- "$OPTS"

CORE_PATH=""
BOOT=0
DO_BOOT=0 # private flag..
LIM_SCREENRC=""


while [ $# -gt 0 ]; do
    case $1 in 
        -h|--help)              print_version; print_help; exit 0;;
        -v|--version)           print_version; exit 0;;
        -b|--boot)              BOOT=1
                                case "$2" in 
                                    "") shift 2;;
                                    *) CORE_PATH=$2; shift 2;;
                                esac ;;
        -l|--list)              list_running_lisps
                                exit 0;;
        # magic!
        --private-do-boot)      DO_BOOT=1; shift 1;;
        --private-lim-screenrc) case "$2" in 
                                    "") shift 2;;
                                    *) LIM_SCREENRC=$2; shift 2;;
                                esac ;;
        --) shift; break;;
        *) echo "Internal error: option processing error: $1" 1>&2;  exit 1;;
    esac
done

NAME="$1"

#
# this is called from 'lispscreenrc'.
# 
if [[ "$DO_BOOT" == "1" ]]; then

	pos=$(expr index $STY .)
	id=${STY:0:$pos-1}
	name=${STY:$pos+13}
	screen -x $STY -p 0 -X eval "hardstatus alwayslastline \"%{= bW}Lim on SBCL %35= <F12> to disconnect, C-d to quit %= $name ($id)\""

    core=""
    if [[ "$CORE_PATH" != "" ]]; then
        core="--core $CORE_PATH"
    fi
	#rlwrap -b $BREAK_CHARS sbcl $core
    sbcl $core

    # cleanup screenrc
    rm -rf "$LIM_SCREENRC"

#
# first part of the Lisp screen startup
#
elif [[ "$BOOT" == "1" ]]; then
    
    if [[ "$NAME" == "" ]]; then
        echo "Sorry, must name your Lisp."
        print_help
        exit 1
    fi

    core_opt=""
    if [[ "$CORE_PATH" != "" ]]; then
        core_opt="--boot=$CORE_PATH"
    fi

    initfile=$(tempfile -s lim_bridge-screenrc)
    cp -f lispscreenrc $initfile
    echo "screen -t Lisp 0 $HOME/hacking/lim/trunk/startlisp.sh $core_opt --private-lim-screenrc=$initfile --private-do-boot" >> $initfile
    screen -c $initfile -dmS lim_listener-$NAME 

    list_running_lisps
    exit 0
else

    #
    # connect to a running Lisp
    #
    if [[ "$NAME" == "" ]]; then
        echo "Please tell me which Lisp to connect to."
        print_help
        echo
        list_running_lisps
        exit 1
    else
        # try attaching as PID first
        screen -A -x $NAME 2>&1 > /dev/null

        if [[ $? -gt 0 ]]; then
            # if that didn't work, try the readable name
            screen -A -x lim_listener-$NAME 2>&1 > /dev/null
            if [[ $? -gt 0 ]]; then
                echo "Couldn't connect to the Lisp named $NAME."
                list_running_lisps
                exit 1
            fi
        fi
    fi
fi
