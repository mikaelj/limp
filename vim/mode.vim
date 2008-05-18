" 
" limp/vim/mode.vim
"
" URL:
" http://mikael.jansson.be
"
" Description:
" Lisp-mode specific functions (such as leaving/entering buffers)
"
" Version:
" 0.2
"
" Date:
" 2008-04-20
"
" Authors:
" Mikael Jansson <mail@mikael.jansson.be>
"
" Changelog:
" 2008-04-20
" * Initial version.

fun! LimpMode_enter()

  " ls = laststatus (always visible for ls=2)
  " bs = backspace (works over all text for bs=2)
  " si = smartindent
  " et = expandtabs (soft tabs)
  " sw = indent by shift (<> or Tab)
  " ts = tabstop
  " tw = textwidth (don't break lines)
  " nocul = nocursorline

  setlocal syntax=lisp lisp
  setlocal ls=2 bs=2 si et sw=2 ts=2 tw=0 nocul
  setlocal statusline=%<%f\ \(%{LimpBridge_connection_status()}\)\ %h%m%r%=%-14.(%l,%c%V%)\ %P\ of\ %L\ \(%.45{getcwd()}\)
  setlocal iskeyword=&,*,+,45,/,48-57,:,<,=,>,@,A-Z,a-z,_
 
  call LimpHighlight_start()
  call AutoClose_start()

  let g:Limp_active = 1

endfun

"-------------------------------------------------------------------

fun! LimpMode_leave()
  call LimpHighlight_stop()
  call AutoClose_stop()
  let g:Limp_active = 0
endfun

"-------------------------------------------------------------------

augroup LimpMode
  au!
  "XXX: filetype plugin!
  au FileType lisp call LimpMode_enter()|au BufEnter <buffer> call LimpMode_enter()|au BufLeave <buffer> call LimpMode_leave()

augroup END

