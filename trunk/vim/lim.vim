" 
" lim/vim/lim.vim
"
" Description:
" Setup the Lim environment
"
" Version:
" 2008-04-20
"
" Authors:
" Mikael Jansson <mail@mikael.jansson.be>
"
" Changelog:
" 2008-04-20
" Initial version.

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
nmap <F10> 	      :call LimBridge_connect()<CR>

"-------------------------------------------------------------------
" key bindings
"-------------------------------------------------------------------

" Eval Top:           send top-level s-exp to Lisp
" Eval Current:       send current s-exp to Lisp
" Eval Expression:    send arbitrary code to Lisp

noremap <Leader>let   :call LimBridge_eval_top_form()<CR>
noremap <Leader>lec   :call LimBridge_eval_current_form()<CR>
noremap <Leader>lex   :call LimBridge_prompt_eval_expression()<CR>

" Eval Block:         visual mode

vnoremap <Leader>leb  :call LimBridge_eval_block()<cr>
vnoremap <Leader>let  <Leader>leb
vnoremap <Leader>lec  <Leader>leb

" SBCL Abort Reset:   go up one level
" SBCL Abort Quit:    quit the running Lisp

noremap <Leader>lar   :call LimBridge_send_to_lisp( "ABORT\n" )<CR>
noremap <Leader>laq   :call LimBridge_send_to_lisp( "(sb-ext:quit)\n" )<CR>

" Abort Interrupt:    send ^C to interpreter
noremap <Leader>lai  :call LimBridge_send_to_lisp( "" )<CR>

" Stuff Test:         copy current s-exp to test buffer: Stuff Test buffer
noremap <Leader>lst  :call  LimBridge_stuff_current_form()<CR>

" Load File:          load /this/ file into Lisp
" Load Any File:      load whichever version of this file (.lisp not given)
noremap <Leader>llf   :call LimBridge_send_to_lisp( "(load \"" . expand( "%:p" ) . "\")\n")<CR>
noremap <Leader>lla   :call LimBridge_send_to_lisp( "(load \"" . expand( "%:p:r" ) . "\")\n")<CR>

" Compile File:       compile the current file
" Compile Load File:  compile, then load the current file
noremap <Leader>lcf   :call LimBridge_send_to_lisp("(compile-file \"".expand("%:p")."\")\n")<CR>
noremap <Leader>lcl   <Leader>lcf<Leader>lla

" Goto Test Buffer:
" Goto Split:         split current buffer and goto test buffer
noremap <Leader>lgt   :call LimBridge_goto_buffer_or_window(g:lim_bridge_test)<CR>
noremap <Leader>lgs   :sb <bar> call LimBridge_goto_buffer_or_window(g:lim_bridge_test)<CR>
"noremap <Leader>sb    :exe "hide bu" g:lim_bridge_scratch<cr>

" Goto Last:          return to s:lim_bridge_last_lisp, i.e. last buffer
noremap <Leader>lgl   :call LimBridge_goto_buffer_or_window(s:lim_bridge_last_lisp)<CR>

" HyperSpec:
noremap <Leader>lhe   :call LimBridge_hyperspec("exact", 0)<CR>
noremap <Leader>lhp   :call LimBridge_hyperspec("prefix", 1)<CR>
noremap <Leader>lhs   :call LimBridge_hyperspec("suffix", 1)<CR>
noremap <Leader>lhg   :call LimBridge_hyperspec("grep", 1)<CR>
noremap <Leader>lhi   :call LimBridge_hyperspec("index", 0)<CR>
noremap <Leader>lhI   :call LimBridge_hyperspec("index-page", 0)<CR>

" Help Describe:      ask Lisp about the current symbol
noremap <Leader>lhd   :call LimBridge_send_to_lisp("(describe '".expand("<cword>").")")<CR>

" map the "man" command to do an exact lookup in the Hyperspec
nmap K <Leader>lhe

