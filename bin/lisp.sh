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
    screen -ls | sed -ne 's/[^0-9]\+\([0-9]\+\)\.lim_listener-\([a-z0-9]\+\).*/  \2 (\1)/p' | sort -k1,1
}

SHORTOPTS="hvb::lp:P:"
LONGOPTS="help,version,boot::,list,private-do-boot:,private-lim-screenrc:"

OPTS=$(getopt -o $SHORTOPTS --long $LONGOPTS -n "$progname" -- "$@")
eval set -- "$OPTS"

CORE_PATH=""
BOOT=0
DO_BOOT=0 # private flag..
LIM_SCREENRC="" # created at runtime to boot Lisp
LIM_SCREEN_STY_FILE="" # temp file used to grab the STY of the last created screen


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
        --private-do-boot)      DO_BOOT=1;
                                case "$2" in 
                                    "") echo "--private-do-boot must be given a file containing the STY of the last screen process"; exit 1;;
                                    *) LIM_SCREEN_STY_FILE=$2; shift 2;;
                                esac ;;
        --private-lim-screenrc) case "$2" in 
                                    "") echo "--private-lim-screenrc must have a flag"; exit 1;;
                                    *) LIM_SCREENRC=$2; shift 2;;
                                esac ;;
        --) shift; break;;
        *) echo "Internal error: option processing error: $1" 1>&2;  exit 1;;
    esac
done

NAME="$1"


SCREENRC_DATA="
\n    startup_message off      # default: on
\n    defscrollback   1000
\n    hardcopydir     $HOME/.lim-hardcopy
\n    logstamp        off
\n    shell           bash
\n    caption         splitonly
\n    escape          ^zz
\n    
\n    ## scrolling
\n    termcapinfo     xterm ti@:te@
\n    
\n    # <S-PageUp>, <S-PageDown>: Scroll
\n    bindkey -m \"^[[5;2~\" stuff ^u
\n    bindkey -m \"^[[6;2~\" stuff ^d
\n    
\n    # <F12>: Detach
\n    bindkey -k F2 detach
\n    
\n    # this is so we can send large amounts of text through 'readbuf'/'paste .'
\n    obulimit        20971520 # 20M should to be enough
\n    
\n    # have to remove delay or screen will drop chars.
\n    msgwait         0
\n    msgminwait      0
\n    
\n    # no flow control
\n    defflow         off
"

#
# this is executed from inside the screen
# 
if [[ "$DO_BOOT" == "1" ]]; then

    pos=$(expr index $STY .)
    id=${STY:0:$pos-1}
    name=${STY:$pos+13}
    lisp=$(sbcl --version)
    LIM_BRIDGE_CHANNEL="$HOME/.lim_bridge_channel-$name.$id"
    touch $LIM_BRIDGE_CHANNEL

    # magic goes here
    screen -x $STY -p 0 -X eval "hardstatus alwayslastline \"%{= bW}Lim on $lisp %35= <F12> to disconnect, C-d to quit. (escape is C-z) %= $name ($id)\""
    screen -x $STY -p 0 -X eval "bufferfile $LIM_BRIDGE_CHANNEL"
    screen -x $STY -p 0 -X eval "register . $STY"
    screen -x $STY -p 0 -X eval "writebuf $LIM_SCREEN_STY_FILE"

    core=""
    if [[ "$CORE_PATH" != "" ]]; then
        core="--core $CORE_PATH"
    fi

    # do we have rlwrap? very useful utility
    RLWRAP=""
    BREAK_CHARS="\"#'(),;\`\\|!?[]{}"
    [[ `which rlwrap` ]] && RLWRAP="rlwrap -b $BREAK_CHARS"

    # command to disable aliases/functions
    echo -e "Welcome to Lim. May your journey be pleasant.\n"
	$RLWRAP sbcl --noinform $core

    # cleanup 
    rm -rf "$LIM_BRIDGE_CHANNEL"
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
    styfile=$(tempfile)
    #cp -f $LIMRUNTIME/lim.screenrc $initfile
    echo -e $SCREENRC_DATA > $initfile
    echo "screen -t Lisp 0 $LIMRUNTIME/bin/lisp.sh $core_opt --private-lim-screenrc=$initfile --private-do-boot=$styfile" >> $initfile

    screen -c $initfile -dmS lim_listener-$NAME 

    # wait for the styfile to become available
    while [[ ! -s $styfile ]]; do
        sleep 1s
    done

    # to give the STY back to Vim
    cat $styfile
    rm -f $styfile

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
            screen -x lim_listener-$NAME  2>&1 > /dev/null
            if [[ $? -gt 0 ]]; then
                echo "Couldn't connect to the Lisp named $NAME."
                list_running_lisps
                exit 1
            fi
        fi
    fi
fi
