" 
" lim/vim/lim.vim
"
" URL:
" http://mikael.jansson.be/hacking
"
" Description:
" Setup the Lim environment
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
" * 2008-04-25 by Mikael Jansson <mail@mikael.jansson.be>
"   Catch-all key <F12> for Lisp boot, connect & display
"
" * 2008-04-20 by Mikael Jansson <mail@mikael.jansson.be>
"   Initial version.

set nocompatible
syntax on
filetype plugin indent on

"-------------------------------------------------------------------
" display info about Lisp
"-------------------------------------------------------------------
set statusline=%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P\ of\ %L\ \(%.45{getcwd()}\)

"-------------------------------------------------------------------
" coloring
"-------------------------------------------------------------------
set t_Co=256

hi Brackets ctermbg=53 ctermfg=white 
hi BracketsBlock ctermbg=235 guibg=lightgray
hi StatusLine ctermbg=white ctermfg=160
hi StatusLineNC ctermbg=black ctermfg=gray

"-------------------------------------------------------------------
" external dependencies
"-------------------------------------------------------------------
silent! runtime plugin/matchit.vim

"-------------------------------------------------------------------
" the Lim library
"-------------------------------------------------------------------

" prefix for the pipe used for communication
let g:lim_bridge_channel_base = $HOME . "/.lim_bridge_channel-"

" load the rest of the code
runtime lim/lim-mode.vim
runtime lim/lim-cursor.vim
runtime lim/lim-highlight.vim
runtime lim/lim-sexp.vim
runtime lim/lim-bridge.vim
runtime lim/lim-autoclose.vim

"-------------------------------------------------------------------
" boot Lim
"-------------------------------------------------------------------
nmap <F12> 	          :call LimBridge_boot_or_connect_or_display()<CR>
nmap <C-F12> 	      :call LimBridge_disconnect()<CR>

"-------------------------------------------------------------------
" key bindings
"-------------------------------------------------------------------

" Eval Top:           send top-level s-exp to Lisp
" Eval Current:       send current s-exp to Lisp
" Eval Expression:    send arbitrary code to Lisp

noremap <Leader>et   :call LimBridge_eval_top_form()<CR>
noremap <Leader>ec   :call LimBridge_eval_current_form()<CR>
noremap <Leader>ex   :call LimBridge_prompt_eval_expression()<CR>

" Eval Block:         visual mode

vnoremap <Leader>eb  :call LimBridge_eval_block()<cr>
vnoremap <Leader>et  <Leader>leb
vnoremap <Leader>ec  <Leader>leb

" SBCL Abort Reset:   go up one level
" SBCL Abort Quit:    quit the running Lisp

noremap <Leader>ar    :call LimBridge_send_to_lisp( "ABORT\n" )<CR>
noremap <Leader>aq    :call LimBridge_send_to_lisp( "(sb-ext:quit)\n" )<CR>

" Abort Interrupt:    send ^C to interpreter
noremap <Leader>ai    :call LimBridge_send_to_lisp( "" )<CR>

" Stuff Test:         copy current s-exp to test buffer: Stuff Test buffer
noremap <Leader>st    :call  LimBridge_stuff_current_form()<CR>

" Load File:          load /this/ file into Lisp
" Load Any File:      load whichever version of this file (.lisp not given)
noremap <Leader>lf    :call LimBridge_send_to_lisp( "(load \"" . expand( "%:p" ) . "\")\n")<CR>
noremap <Leader>la    :call LimBridge_send_to_lisp( "(load \"" . expand( "%:p:r" ) . "\")\n")<CR>

" Compile File:       compile the current file
" Compile Load File:  compile, then load the current file
noremap <Leader>cf    :call LimBridge_send_to_lisp("(compile-file \"".expand("%:p")."\")\n")<CR>
noremap <Leader>cl    <Leader>lcf<Leader>lla

" Goto Test Buffer:
" Goto Split:         split current buffer and goto test buffer
noremap <Leader>gt   :call LimBridge_goto_buffer_or_window(g:lim_bridge_test)<CR>
noremap <Leader>gs   :sb <bar> call LimBridge_goto_buffer_or_window(g:lim_bridge_test)<CR>
"noremap <Leader>sb    :exe "hide bu" g:lim_bridge_scratch<cr>

" Goto Last:          return to s:lim_bridge_last_lisp, i.e. last buffer
noremap <Leader>gl   :call LimBridge_goto_buffer_or_window(s:lim_bridge_last_lisp)<CR>

" HyperSpec:
noremap <Leader>he   :call LimBridge_hyperspec("exact", 0)<CR>
noremap <Leader>hp   :call LimBridge_hyperspec("prefix", 1)<CR>
noremap <Leader>hs   :call LimBridge_hyperspec("suffix", 1)<CR>
noremap <Leader>hg   :call LimBridge_hyperspec("grep", 1)<CR>
noremap <Leader>hi   :call LimBridge_hyperspec("index", 0)<CR>
noremap <Leader>hI   :call LimBridge_hyperspec("index-page", 0)<CR>

" Help Describe:      ask Lisp about the current symbol
noremap <Leader>hd   :call LimBridge_send_to_lisp("(describe '".expand("<cword>").")")<CR>

" map the "man" command to do an exact lookup in the Hyperspec
nmap K <Leader>he

