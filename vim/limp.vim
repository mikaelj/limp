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

setlocal nocompatible
syntax on

"-------------------------------------------------------------------
"-------------------------------------------------------------------
" coloring
"-------------------------------------------------------------------
if !exists("g:colors_name")
    set t_Co=256
    color desert256
endif

hi Brackets      ctermbg=53 ctermfg=white 
hi BracketsBlock ctermbg=235 guibg=lightgray
hi StatusLine    ctermbg=white ctermfg=160
hi StatusLineNC  ctermbg=black ctermfg=gray
hi Pmenu         ctermbg=53 ctermfg=255
hi PmenuSel      ctermbg=255 ctermfg=53

"-------------------------------------------------------------------
" external dependencies
"-------------------------------------------------------------------
silent! runtime plugin/matchit.vim

"-------------------------------------------------------------------
" the Limp library
"-------------------------------------------------------------------

" load the rest of the code
runtime ftplugin/lisp/limp/mode.vim
runtime ftplugin/lisp/limp/cursor.vim
runtime ftplugin/lisp/limp/highlight.vim
runtime ftplugin/lisp/limp/sexp.vim
runtime ftplugin/lisp/limp/bridge.vim
runtime ftplugin/lisp/limp/autoclose.vim


setlocal syntax=lisp lisp
setlocal ls=2 bs=2 si et sw=2 ts=2 tw=0 nocul
setlocal statusline=%<%f\ \(%{LimpBridge_connection_status()}\)\ %h%m%r%=%-14.(%l,%c%V%)\ %P\ of\ %L\ \(%.45{getcwd()}\)
setlocal iskeyword=&,*,+,45,/,48-57,:,<,=,>,@,A-Z,a-z,_

call LimpHighlight_start()
call AutoClose_start()

"-------------------------------------------------------------------
" reset to previous values
"-------------------------------------------------------------------

" to allow for line continuations
let s:save_cpo = &cpo
set cpo&vim

let b:undo_ftplugin = "setlocal syntax< lisp< ls< bs< si< et< sw<"
    \ . "ts< tw< nocompatible< nocul< statusline< iskeyword<"
    \ . "| call LimpHighlight_stop()"
    \ . "| call AutoClose_stop()"

" restore line continuations
let &cpo = s:save_cpo
unlet s:save_cpo

"-------------------------------------------------------------------
" plugin <-> function mappings
"-------------------------------------------------------------------

nnoremap <buffer> <unique> <Plug>LimpBootConnectDisplay  :call LimpBridge_boot_or_connect_or_display()<CR>
nnoremap <buffer> <unique> <Plug>LimpDisconnect          :call LimpBridge_disconnect()<CR>
nnoremap <buffer> <unique> <Plug>LimpShutdownLisp        :call LimpBridge_shutdown_lisp()<CR>

nnoremap <buffer> <unique> <Plug>EvalTop        :call LimpBridge_eval_top_form()<CR>
nnoremap <buffer> <unique> <Plug>EvalCurrent    :call LimpBridge_eval_current_form()<CR>
nnoremap <buffer> <unique> <Plug>EvalExpression :call LimpBridge_prompt_eval_expression()<CR>

vnoremap <buffer> <unique> <Plug>EvalBlock      :call LimpBridge_eval_block()<cr>

nnoremap <buffer> <unique> <Plug>AbortReset     :call LimpBridge_send_to_lisp( "ABORT\n" )<CR>
nnoremap <buffer> <unique> <Plug>AbortInterrupt :call LimpBridge_send_to_lisp( "" )<CR>

nnoremap <buffer> <unique> <Plug>TestCurrent    :call  LimpBridge_stuff_current_form()<CR>
nnoremap <buffer> <unique> <Plug>TestTop        :call  LimpBridge_stuff_top_form()<CR>

nnoremap <buffer> <unique> <Plug>LoadThisFile    :call LimpBridge_send_to_lisp( "(load \"" . expand( "%:p" ) . "\")\n")<CR>
nnoremap <buffer> <unique> <Plug>LoadAnyFile     :call LimpBridge_send_to_lisp( "(load \"" . expand( "%:p:r" ) . "\")\n")<CR>

nnoremap <buffer> <unique> <Plug>CompileFile        :call LimpBridge_send_to_lisp("(compile-file \"".expand("%:p")."\")\n")<CR>
nnoremap <buffer> <unique> <Plug>CompileAndLoadFile <Plug>CompileFile<Plug>LoadAnyFile

" Goto Test Buffer:
" Goto Split:         split current buffer and goto test buffer
nnoremap <buffer> <unique> <Plug>GotoTestBuffer           :call LimpBridge_goto_buffer_or_window(g:limp_bridge_test)<CR>
nnoremap <buffer> <unique> <Plug>GotoTestBufferAndSplit   :sb <bar> call LimpBridge_goto_buffer_or_window(g:limp_bridge_test)<CR>

" Goto Last:          return to g:limp_bridge_last_lisp, i.e. last buffer
nnoremap <buffer> <unique> <Plug>GotoLastLispBuffer   :call LimpBridge_goto_buffer_or_window(g:limp_bridge_last_lisp)<CR>

" HyperSpec:
nnoremap <buffer> <unique> <Plug>HyperspecExact    :call LimpBridge_hyperspec("exact", 0)<CR>
nnoremap <buffer> <unique> <Plug>HyperspecPrefix   :call LimpBridge_hyperspec("prefix", 1)<CR>
nnoremap <buffer> <unique> <Plug>HyperspecSuffix   :call LimpBridge_hyperspec("suffix", 1)<CR>
nnoremap <buffer> <unique> <Plug>HyperspecGrep             :call LimpBridge_hyperspec("grep", 1)<CR>
nnoremap <buffer> <unique> <Plug>HyperspecFirstLetterIndex :call LimpBridge_hyperspec("index", 0)<CR>
nnoremap <buffer> <unique> <Plug>HyperspecFullIndex   :call LimpBridge_hyperspec("index-page", 0)<CR>

" Help Describe:      ask Lisp about the current symbol
nnoremap <buffer> <unique> <Plug>HelpDescribe   :call LimpBridge_send_to_lisp("(describe '".expand("<cword>").")")<CR>

