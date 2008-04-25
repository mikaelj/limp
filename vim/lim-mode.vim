" 
" lim/vim/lim-mode.vim
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

let g:lisp_rainbow=1
let g:lim_bridge_id="<disconnected>"
let g:lim_bridge_channel_base = $HOME . "/.lim_bridge_channel-"

augroup LimMode
 au!
 au BufEnter .lim_bridge_test*,*.lisp,*.asd setlocal syntax=lisp filetype=lisp lisp 
 "
 " ls = laststatus (always visible for ls=2)
 " bs = backspace (works over all text for bs=2)
 " si = smartindent
 " et = expandtabs (soft tabs)
 " sw = indent by shift (<> or Tab)
 " ts = tabstop
 " tw = textwidth (don't break lines)
 " nocul = nocursorline
 "
 au BufEnter .lim_bridge_test*,*.lisp,*.asd setlocal ls=2 bs=2 si et sw=2 ts=2 tw=0 nocul

 au BufEnter .lim_bridge_test*,*.lisp,*.asd setlocal statusline=%<%f\ \(%{g:lim_bridge_id}\)\ %h%m%r%=%-14.(%l,%c%V%)\ %P\ of\ %L\ \(%.45{getcwd()}\)

 au BufEnter .lim_bridge_test*,*.lisp,*.asd call LimHighlight_start()|call AutoClose_start()
 au BufLeave .lim_bridge_test*,*.lisp,*.asd call LimHighlight_stop()|call AutoClose_stop()

 au Filetype lisp imap ä (
 au Filetype lisp imap ö )
 au Filetype lisp nmap ä a(
 au Filetype lisp nmap Ö a)
augroup END

