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
nnoremap <buffer> <Plug>MarkTop 99[(V%

" Format Current:     reindent/format
" Format Top:    
nnoremap <buffer> <Plug>FormatCurrent   [(=%`'
nnoremap <buffer> <Plug>FormatTop       99[(=%`'

" Sexp Wrap: 	     wrap the current form in a list
" Sexp Peel:         peel a list off the current form
nnoremap <silent> <buffer> <Plug>SexpWrap   :call Cursor_push()<CR>[(%a)<ESC>h%i(<ESC>:call Cursor_pop()<CR>
nnoremap <silent> <buffer> <Plug>SexpPeel   :call Cursor_push()<CR>[(:call Cursor_push()<CR>%x:call Cursor_pop()<CR>x:call Cursor_pop()<CR>

" Sexp Comment:      comment all the way from the top level
nnoremap <silent> <buffer> <Plug>SexpComment   :call Cursor_push()<CR>99[(%a\|#<ESC>hh%i#\|<ESC>:call Cursor_pop()<CR>

" Sexp Comment Current:    comment current form
nnoremap <silent> <buffer> <Plug>SexpCommentCurrent :call Cursor_push()<CR>[(%a\|#<ESC>hh%i#\|<ESC>:call Cursor_pop()<CR>

