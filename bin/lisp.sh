#!/bin/bash

#
# lisp.sh
#
# Boot a new Lisp, or attach to an existing.
#

# full path to location of the SBCL binary and its default core.
# default is to guess the correct location, which usually gets it right.
SBCL=
SBCL_CORE=

# ----------------------------

progname=lisp.sh
VERSION=0.3.4

LIMPDIR=${LIMPRUNTIME:-/usr/local/limp/$VERSION}

if [[ "$SBCL" == "" ]]; then
    # guess for OS X
    if [[ "$(uname)" == "Darwin" ]]; then
        SBCL=/opt/usr/local/bin/sbcl
        [[ "$SBCL_CORE" == "" ]] && SBCL_CORE=/opt/usr/local/lib/sbcl/sbcl.core
    else
        # default to something in PATH
        SBCL=`which sbcl`
        [[ "$SBCL_CORE" == "" ]] && SBCL_CORE=$(dirname $(dirname $SBCL))/lib/sbcl/sbcl.core

        if [[ "$SBCL" == "" || ! -x "$SBCL" ]]; then
            echo "lisp.sh: sbcl binary not found. Set location of SBCL in lisp.sh"
        fi
    fi
fi

print_version() {
    echo "$progname $VERSION."
}

print_help() {
    cat <<EOF

Usage: $progname [options] [name-or-PID]
Connects to the Lisp specified by name-or-PID, or boot a new called 'name'.

Options:
  -h          Print help (this text) and exit
  -v          Print version information and exit
  -b          Boot a fresh Lisp
  -c path     Use the specified core instead of the default
  -l          Display running Lisps
  -s styfile  Put the screen ID in this file, otherwise
              display on standard output.

  Name must be unique! (But isn't currently enforced.)

Examples:
  # connect to a running Lisp named mylisp
  $progname mylisp

  # boot a new Lisp, using the specified core
  $progname -b -c /path/to/my/huge-app.core mylisp
EOF
}
list_running_lisps() {
    echo "Currently running Lisps:"
    screen -ls | sed -ne 's/[^0-9]\+\([0-9]\+\)\.limp_listener-\([a-z0-9]\+\).*/  \2 (\1)/p' | sort -k1,1
}

SHORTOPTS="hvblc:s:p:P:"

export GETOPT_COMPATIBLE=1
OPTS=$(getopt $SHORTOPTS $*)
set -- $OPTS

CORE_PATH=""
BOOT=0
DO_BOOT=0 # private flag..
LIMP_SCREENRC="" # created at runtime to boot Lisp
LIMP_SCREEN_STY_FILE="" # temp file used to grab the STY of the last created screen

while [ $# -gt 0 ]; do
    case $1 in 
        -h)         print_version; print_help; exit 0;;
        -v)         print_version; exit 0;;
        -b)         BOOT=1; shift;;
        -c)         case "$2" in 
                      "") shift 2;;
                       *) CORE_PATH=$2; shift 2;;
                    esac ;;
        -l)         list_running_lisps
                    exit 0;;
        -s)         case "$2" in
                        "") echo "-s must be given a file to write the screen ID to"; 
                            exit 1;;
                        *) LIMP_SCREEN_STY_FILE=$2; shift 2;;
                    esac ;;
        # magic!
        -p)         DO_BOOT=1;
                    case "$2" in 
                        "") echo "-p must be given a file containing the STY of the last screen process"; 
                            exit 1;;
                        *) LIMP_SCREEN_STY_FILE=$2; shift 2;;
                    esac ;;
        -P)         case "$2" in 
                        "") echo "-P must be given a file containing the screenrc"; exit 1;;
                        *) LIMP_SCREENRC=$2; shift 2;;
                    esac ;;
        --) shift; break;;
        *) echo "Internal error: option processing error: $1" 1>&2;  exit 1;;
    esac
done

NAME="$1"


#
# this is executed from inside the screen
# 
if [[ "$DO_BOOT" == "1" ]]; then

    id=$(echo $STY | cut -d '.' -f 1)
    # in case someone gives it a name like 'lots-of-silly-parens-and-silly-dashes'
    name=$(echo $STY | cut -d '-' -f 2,3,4,5,6,7,8,9)
    lisp=$($SBCL --version)
    LIMP_BRIDGE_CHANNEL="$HOME/.limp_bridge_channel-$name.$id"
    touch $LIMP_BRIDGE_CHANNEL

    # magic goes here
    if [[ "$CORE_PATH" != "" ]]; then
        lisp="$CORE_PATH ($lisp)"
    else
        lisp="($lisp)"
    fi
    screen -x $STY -p 0 -X eval "hardstatus alwayslastline \"%{= bW}Limp: F12 to hide. %30= $lisp %= $name ($id)\""
    screen -x $STY -p 0 -X eval "bufferfile $LIMP_BRIDGE_CHANNEL"
    screen -x $STY -p 0 -X eval "register . $STY"
    screen -x $STY -p 0 -X eval "writebuf $LIMP_SCREEN_STY_FILE"

    core=""
    if [[ "$CORE_PATH" != "" ]]; then
        core="--core $CORE_PATH"
    fi

    # do we have rlwrap? very useful utility
    RLWRAP=""
    BREAK_CHARS="\"#'(),;\`\\|!?[]{}"
    [[ `which rlwrap` ]] && RLWRAP="rlwrap -b $BREAK_CHARS"

    # command to disable aliases/functions
    echo -e "Welcome to Limp. May your journey be pleasant.\n"
	$RLWRAP $SBCL --noinform $core

    # cleanup 
    rm -rf "$LIMP_BRIDGE_CHANNEL"
    rm -rf "$LIMP_SCREENRC"
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
        core_opt="-c $CORE_PATH"
    else
        core_opt="-c $SBCL_CORE"
    fi

    initfile=$(mktemp /tmp/limp_bridge-screenrc.XXXXXX)
    if [[ "$LIMP_SCREEN_STY_FILE" == "" ]]; then
        styfile=$(mktemp /tmp/limp_sty_XXXXXX)
    else
        styfile=$LIMP_SCREEN_STY_FILE
    fi

    #
    # to work around braindead versions of echo without -e
    #
    echo "startup_message off" >> $initfile
    echo "defscrollback   1000" >> $initfile
    echo "hardcopydir     $HOME/.limp-hardcopy" >> $initfile
    echo "logstamp        off" >> $initfile
    echo "shell           bash" >> $initfile
    echo "caption         splitonly" >> $initfile
    echo "escape          ^zz" >> $initfile

    # scrolling
    echo "termcapinfo     xterm ti@:te@" >> $initfile

    # <S-PageUp>, <S-PageDown>: Scroll
    echo "bindkey -m \"^[[5;2~\" stuff ^u" >> $initfile
    echo "bindkey -m \"^[[6;2~\" stuff ^d" >> $initfile

    # <F12>: Detach
    echo "bindkey -k F2 detach" >> $initfile

    # this is so we can send large amounts of text through 'readbuf'/'paste .'
    echo "obulimit        20971520 # 20M should to be enough" >> $initfile

    # have to remove delay or screen will drop chars.
    echo "msgwait         0" >> $initfile
    echo "msgminwait      0" >> $initfile

    # no flow control
    echo "defflow         off" >> $initfile

    echo "screen -t Lisp 0 $LIMPDIR/bin/lisp.sh $core_opt -P $initfile -p $styfile" >> $initfile

    screen -c $initfile -dmS limp_listener-$NAME 

    # wait for the styfile to become available
    while [ ! -s $styfile ]; do
        sleep 1s
    done

    if [[ "$LIMP_SCREEN_STY_FILE" == "" ]]; then

        # to give the STY back to Vim
        cat $styfile
        rm -f $styfile
    fi

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
        screen -x $NAME  2>&1 > /dev/null

        if [[ $? -gt 0 ]]; then
            # if that didn't work, try the readable name
            screen -x limp_listener-$NAME  2>&1 > /dev/null
            if [[ $? -gt 0 ]]; then
                echo "Couldn't connect to the Lisp named $NAME."
                list_running_lisps
                exit 1
            fi
        fi
    fi
fi
