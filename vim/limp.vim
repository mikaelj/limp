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

if &co == 1
    set nocompatible
endif
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
if !exists("g:colors_name")
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
" the Lim library
"-------------------------------------------------------------------

" load the rest of the code
runtime limp/mode.vim
runtime limp/cursor.vim
runtime limp/highlight.vim
runtime limp/sexp.vim
runtime limp/bridge.vim
runtime limp/autoclose.vim

"-------------------------------------------------------------------
" boot Lim
"-------------------------------------------------------------------
nmap <F12> 	          :call LimpBridge_boot_or_connect_or_display()<CR>
nmap <C-F12> 	      :call LimpBridge_disconnect()<CR>
nmap <S-F12> 	      :call LimpBridge_shutdown_lisp()<CR>

"-------------------------------------------------------------------
" key bindings
"-------------------------------------------------------------------

" Eval Top:           send top-level s-exp to Lisp
" Eval Current:       send current s-exp to Lisp
" Eval Expression:    send arbitrary code to Lisp

noremap <Leader>et   :call LimpBridge_eval_top_form()<CR>
noremap <Leader>ec   :call LimpBridge_eval_current_form()<CR>
noremap <Leader>ex   :call LimpBridge_prompt_eval_expression()<CR>

" Eval Block:         visual mode

vnoremap <Leader>eb  :call LimpBridge_eval_block()<cr>
vnoremap <Leader>et  <Leader>leb
vnoremap <Leader>ec  <Leader>leb

" SBCL Abort Reset:   go up one level
noremap <Leader>ar    :call LimpBridge_send_to_lisp( "ABORT\n" )<CR>

" Abort Interrupt:    send ^C to interpreter
noremap <Leader>ai    :call LimpBridge_send_to_lisp( "" )<CR>

" Test Current:       copy current s-exp to test buffer
noremap <Leader>tc    :call  LimpBridge_stuff_current_form()<CR>
noremap <Leader>tt    :call  LimpBridge_stuff_top_form()<CR>

" Load File:          load /this/ file into Lisp
" Load Any File:      load whichever version of this file (.lisp not given)
noremap <Leader>lf    :call LimpBridge_send_to_lisp( "(load \"" . expand( "%:p" ) . "\")\n")<CR>
noremap <Leader>la    :call LimpBridge_send_to_lisp( "(load \"" . expand( "%:p:r" ) . "\")\n")<CR>

" Compile File:       compile the current file
" Compile Load File:  compile, then load the current file
noremap <Leader>cf    :call LimpBridge_send_to_lisp("(compile-file \"".expand("%:p")."\")\n")<CR>
noremap <Leader>cl    <Leader>cf<Leader>la

" Goto Test Buffer:
" Goto Split:         split current buffer and goto test buffer
noremap <Leader>gt   :call LimpBridge_goto_buffer_or_window(g:limp_bridge_test)<CR>
noremap <Leader>gs   :sb <bar> call LimpBridge_goto_buffer_or_window(g:limp_bridge_test)<CR>
"noremap <Leader>sb    :exe "hide bu" g:limp_bridge_scratch<cr>

" Goto Last:          return to g:limp_bridge_last_lisp, i.e. last buffer
noremap <Leader>gl   :call LimpBridge_goto_buffer_or_window(g:limp_bridge_last_lisp)<CR>

" HyperSpec:
noremap <Leader>he   :call LimpBridge_hyperspec("exact", 0)<CR>
noremap <Leader>hp   :call LimpBridge_hyperspec("prefix", 1)<CR>
noremap <Leader>hs   :call LimpBridge_hyperspec("suffix", 1)<CR>
noremap <Leader>hg   :call LimpBridge_hyperspec("grep", 1)<CR>
noremap <Leader>hi   :call LimpBridge_hyperspec("index", 0)<CR>
noremap <Leader>hI   :call LimpBridge_hyperspec("index-page", 0)<CR>

" Help Describe:      ask Lisp about the current symbol
noremap <Leader>hd   :call LimpBridge_send_to_lisp("(describe '".expand("<cword>").")")<CR>

" map the "man" command to do an exact lookup in the Hyperspec
nmap K <Leader>he

