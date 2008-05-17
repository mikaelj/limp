" 
" limp/vim/sexp.vim
"
" URL:
" http://mikael.jansson.be/hacking
"
" Description:
" Things to help you out with s-exps.
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
" * Based on ViLisp.vim by Larry Clapp <vim@theclapp.org>

" Mark Top:           mark visual block
noremap <Leader>mt   99[(V%

" Format Current:     reindent/format
" Format Top:    
noremap <Leader>fc   [(=%`'
noremap <Leader>ft   99[(=%`'

" Sexp Wrap: 	     wrap the current form in a list
noremap <Leader>sw   :call Cursor_push()<CR>[(%a)<ESC>h%i(<ESC>:call Cursor_pop()<CR>

" Sexp Peel:         peel a list off the current form
noremap <Leader>sp   :call :call Cursor_push()<CR>[(:call Cursor_push()<CR>%x:call Cursor_pop()<CR>x:call Cursor_pop()<CR>

" Sexp Comment:      comment all the way from the top level
noremap <Leader>sc   :call Cursor_push()<CR>99[(%a\|#<ESC>hh%i#\|<ESC>:call Cursor_pop()<CR>

" Sexp comment Current:    comment current form
noremap <Leader>sC   :call Cursor_push()<CR>[(%a\|#<ESC>hh%i#\|<ESC>:call Cursor_pop()<CR>

