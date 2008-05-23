" 
" limp/vim/limp.vim
"
" URL:
" http://mikael.jansson.be/hacking
"
" Description:
" Setup the Limp environment
"
" Version:
" 0.2
"
" Date:
" 2008-04-28
"
" Authors:
" Mikael Jansson <mail@mikael.jansson.be>
"
" Changelog:
" * 2008-04-28 by Mikael Jansson <mail@mikael.jansson.be>
"   Only change colorscheme and nocompatible when not previously set.
"
" * 2008-04-25 by Mikael Jansson <mail@mikael.jansson.be>
"   Catch-all key <F12> for Lisp boot, connect & display
"
" * 2008-04-20 by Mikael Jansson <mail@mikael.jansson.be>
"   Initial version.

"-------------------------------------------------------------------

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

"-------------------------------------------------------------------
" external dependencies
"-------------------------------------------------------------------
silent! runtime plugin/matchit.vim

"-------------------------------------------------------------------
" the Limp library
"-------------------------------------------------------------------

runtime ftplugin/lisp/limp/cursor.vim
runtime ftplugin/lisp/limp/highlight.vim
runtime ftplugin/lisp/limp/sexp.vim
runtime ftplugin/lisp/limp/bridge.vim
runtime ftplugin/lisp/limp/autoclose.vim
runtime ftplugin/lisp/limp/keys.vim
runtime ftplugin/lisp/limp/mode.vim


