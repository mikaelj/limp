" 
" lim-sexp.vim
"
" Description:
" Things to help you out with s-exps.
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
" Based on ViLisp.vim by Larry Clapp <vim@theclapp.org>

" Mark Top:           mark visual block
noremap <Leader>lms   99[(V%

" Format Current:     reindent/format
" Format Top:    
noremap <Leader>lfc   [(=%`'
noremap <Leader>lft   99<Leader>fc

" List Wrap: 	      wrap the current form in a list
noremap <Leader>llw   :call Cursor_push()<CR>[(%a)<ESC>h%i(<ESC>:call Cursor_pop()<CR>

" List Peel:          peel a list off the current form
noremap <Leader>llp   :call :call Cursor_push()<CR>[(:call Cursor_push()<CR>%x:call Cursor_pop()<CR>x:call Cursor_pop()<CR>

" Comment Current:    comment current form
noremap <Leader>lcc   :call Cursor_push()<CR>[(%a\|#<ESC>hh%i#\|<ESC>:call Cursor_pop()<CR>

