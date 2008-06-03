#
# config.mk.in -- autoconf template for Vim on Unix		vim:ts=8:sw=8:
#
# DO NOT EDIT config.mk!!  It will be overwritten by configure.
# Edit Makefile and run "make" or run ./configure with other arguments.
#
# Configure does not edit the makefile directly. This method is not the
# standard use of GNU autoconf, but it has two advantages:
#   a) The user can override every choice made by configure.
#   b) Modifications to the makefile are not lost when configure is run.
#
# I hope this is worth being nonstandard. jw.



VIMNAME		= vim
EXNAME		= ex
VIEWNAME	= view

CC		= gcc
DEFS		= -DHAVE_CONFIG_H
CFLAGS		= -g -O2
CPPFLAGS	= 
srcdir		= .

LDFLAGS		=  -L/usr/local/lib
LIBS		= -lncurses -lnsl  
TAGPRG		= ctags -I INIT+ --fields=+S

CPP		= gcc -E
CPP_MM		= M
DEPEND_CFLAGS_FILTER = | sed 's+-I */+-isystem /+g'
X_CFLAGS	=  
X_LIBS_DIR	=  
X_PRE_LIBS	=  -lSM -lICE
X_EXTRA_LIBS	=  -lXdmcp -lSM -lICE
X_LIBS		= -lXt -lX11

MZSCHEME_LIBS	= 
MZSCHEME_SRC	= 
MZSCHEME_OBJ	= 
MZSCHEME_CFLAGS	= 
MZSCHEME_PRO	= 

PERL		= 
PERLLIB		= 
PERL_LIBS	= 
SHRPENV		= 
PERL_SRC	= 
PERL_OBJ	= 
PERL_PRO	= 
PERL_CFLAGS	= 

ECL_SRC		= if_ecl.c
ECL_OBJ		= objects/if_ecl.o
ECL_CFLAGS	= -Dlinux   -I/home/mikael/local/lib/ecl
ECL_LIBS	= -Wl,--rpath,/home/mikael/local/lib/ecl -L/home/mikael/local/lib/ecl -lecl    -lpthread -ldl  -lm 

PYTHON_SRC	= if_python.c
PYTHON_OBJ	= objects/if_python.o objects/py_config.o
PYTHON_CFLAGS	= -I/usr/include/python2.5 -pthread
PYTHON_LIBS	= -L/usr/lib/python2.5/config -lpython2.5 -lpthread -ldl -lutil -lm -Xlinker -export-dynamic -Wl,-O1 -Wl,-Bsymbolic-functions
PYTHON_CONFDIR	= /usr/lib/python2.5/config
PYTHON_GETPATH_CFLAGS = -DPYTHONPATH='":/usr/lib/python25.zip:/usr/lib/python2.5:/usr/lib/python2.5/plat-linux2:/usr/lib/python2.5/lib-tk:/usr/lib/python2.5/lib-dynload:/usr/local/lib/python2.5/site-packages:/usr/lib/python2.5/site-packages:/usr/lib/python2.5/site-packages/Numeric:/usr/lib/python2.5/site-packages/PIL:/usr/lib/python2.5/site-packages/gst-0.10:/var/lib/python-support/python2.5:/usr/lib/python2.5/site-packages/gtk-2.0:/var/lib/python-support/python2.5/gtk-2.0:/usr/lib/python2.5/site-packages/wx-2.8-gtk2-unicode"' -DPREFIX='"/usr"' -DEXEC_PREFIX='"/usr"'

TCL		= 
TCL_SRC		= 
TCL_OBJ		= 
TCL_PRO		= 
TCL_CFLAGS	= 
TCL_LIBS	= 

HANGULIN_SRC	= 
HANGULIN_OBJ	= 

WORKSHOP_SRC	= 
WORKSHOP_OBJ	= 

NETBEANS_SRC	= netbeans.c
NETBEANS_OBJ	= objects/netbeans.o

RUBY		= 
RUBY_SRC	= 
RUBY_OBJ	= 
RUBY_PRO	= 
RUBY_CFLAGS	= 
RUBY_LIBS	= 

SNIFF_SRC	= 
SNIFF_OBJ	= 

AWK		= gawk

STRIP		= strip

EXEEXT		= 

COMPILEDBY	= 

INSTALLVIMDIFF	= installvimdiff
INSTALLGVIMDIFF	= installgvimdiff
INSTALL_LANGS	= install-languages
INSTALL_TOOL_LANGS	= install-tool-languages

### Line break character as octal number for "tr"
NL		= "\\012"

### Top directory for everything
prefix		= /home/mikael/local

### Top directory for the binary
exec_prefix	= ${prefix}

### Prefix for location of data files
BINDIR		= ${exec_prefix}/bin

### Prefix for location of data files
DATADIR		= ${prefix}/share

### Prefix for location of man pages
MANDIR		= ${prefix}/man

### Do we have a GUI
GUI_INC_LOC	= -I/usr/include/gtk-2.0 -I/usr/lib/gtk-2.0/include -I/usr/include/atk-1.0 -I/usr/include/cairo -I/usr/include/pango-1.0 -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include -I/usr/include/freetype2 -I/usr/include/libpng12 -I/usr/include/pixman-1  
GUI_LIB_LOC	=  
GUI_SRC		= $(GTK_SRC)
GUI_OBJ		= $(GTK_OBJ)
GUI_DEFS	= $(GTK_DEFS)
GUI_IPATH	= $(GTK_IPATH)
GUI_LIBS_DIR	= $(GTK_LIBS_DIR)
GUI_LIBS1	= $(GTK_LIBS1)
GUI_LIBS2	= $(GTK_LIBS2)
GUI_INSTALL	= $(GTK_INSTALL)
GUI_TARGETS	= $(GTK_TARGETS)
GUI_MAN_TARGETS	= $(GTK_MAN_TARGETS)
GUI_TESTTARGET	= $(GTK_TESTTARGET)
GUI_TESTARG	= $(GTK_TESTARG)
GUI_BUNDLE	= $(GTK_BUNDLE)
NARROW_PROTO	= 
GUI_X_LIBS	= 
MOTIF_LIBNAME	= 
GTK_LIBNAME	= -lgtk-x11-2.0 -lgdk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lm -lpangocairo-1.0 -lpango-1.0 -lcairo -lgobject-2.0 -lgmodule-2.0 -ldl -lglib-2.0  

### Any OS dependent extra source and object file
OS_EXTRA_SRC	= 
OS_EXTRA_OBJ	= 

### If the *.po files are to be translated to *.mo files.
MAKEMO		= yes

# Make sure that "make first" will run "make all" once configure has done its
# work.  This is needed when using the Makefile in the top directory.
first: all
