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

runtime ftplugin/lisp/limp/mode.vim
runtime ftplugin/lisp/limp/cursor.vim
runtime ftplugin/lisp/limp/highlight.vim
runtime ftplugin/lisp/limp/sexp.vim
runtime ftplugin/lisp/limp/bridge.vim
runtime ftplugin/lisp/limp/autoclose.vim

"-------------------------------------------------------------------
" init filetype plugin
"-------------------------------------------------------------------
syntax on
setlocal nocompatible nocursorline
setlocal lisp syntax=lisp
setlocal ls=2 bs=2 si et sw=2 ts=2 tw=0 
setlocal statusline=%<%f\ \(%{LimpBridge_connection_status()}\)\ %h%m%r%=%-14.(%l,%c%V%)\ %P\ of\ %L\ \(%.45{getcwd()}\)
setlocal iskeyword=&,*,+,45,/,48-57,:,<,=,>,@,A-Z,a-z,_

call LimpHighlight_start()
call AutoClose_start()

"-------------------------------------------------------------------
" reset to previous values
"-------------------------------------------------------------------

let s:save_cpo = &cpo
set cpo&vim

let b:undo_ftplugin = "setlocal syntax< lisp< ls< bs< si< et< sw<"
    \ . "ts< tw< nocursorline< nocompatible< statusline< iskeyword<"
    \ . "| call LimpHighlight_stop()"
    \ . "| call AutoClose_stop()"

let &cpo = s:save_cpo
unlet s:save_cpo

