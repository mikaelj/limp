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

" Sexp Previous:    navigate to previous s-exp
" Sexp Next:        navigate to previous s-exp
nnoremap <silent> <buffer> <Plug>SexpPrevious :call Sexp_Previous()<CR>
nnoremap <silent> <buffer> <Plug>SexpNext     :call Sexp_Next()<CR>

" Sexp Move Back:       swap this and previous s-exp
" Sexp Move Forward:    swap this and next s-exp
nnoremap <silent> <buffer> <Plug>SexpMoveBack    :call Sexp_MoveBack()<CR>
nnoremap <silent> <buffer> <Plug>SexpMoveForward :call Sexp_MoveForward()<CR>

" Sexp Comment:      comment all the way from the top level
nnoremap <silent> <buffer> <Plug>SexpComment   :call Cursor_push()<CR>99[(%a\|#<ESC>hh%i#\|<ESC>:call Cursor_pop()<CR>

" Sexp Comment Current:    comment current form
nnoremap <silent> <buffer> <Plug>SexpCommentCurrent :call Cursor_push()<CR>[(%a\|#<ESC>hh%i#\|<ESC>:call Cursor_pop()<CR>


"-------------------------------------------------------------------

fun! Sexp_Next()
    let [l, c] = Sexp_get_Next()
    call cursor(l, c)
endfun

fun! Sexp_Previous()
    let [l, c] = Sexp_get_Previous()
    if l == 0 && c == 0
        return
    endif
    call cursor(l, c)
    return
endfun

" return the position of the next s-exp
fun! Sexp_get_Next()
    return searchpos('(', 'nW')
endfun

" return the position of the previous s-exp
fun! Sexp_get_Previous()
    let p = getpos(".")

    " If outside of *any* s-exps, move to the previous s-exp first.
    let [l, c] = searchpairpos('(', '', ')', 'bnW')
    if l == 0 && c == 0
        call searchpos(')', 'Wb')
    endif

    " now, move to the start of this s-exp, wherever it may be.
    let [l, c] = searchpos('(', 'Wnb')

    call setpos(".", p)

    return [l, c]
endfun

"XXX: MoveBack/MoveForward share much code

fun! Sexp_MoveBack()
    " Inside an s-exp?
    let [l, c] = searchpairpos('(', '', ')', 'bcnW')
    if l == 0 || c == 0
        " Nope, 
        return
    endif

    silent! let regs = @*

    " mark the start of this s-exp
    silent! norm! yl
    if @0 != "("
        call Sexp_Previous()
    endif

    "
    " Find out if the previous s-exp is the parent of the current
    "
    " This by searching to the previous s-exp, doing a % and checking either
    " of the following conditions:
    "
    " * prev_line2 == this_line2 && prev_col2 > this_col2
    " * prev_line2 > this_line2
    "
    " where prev_line2/prev_col2 = the ) of the previous match, and
    "       this_line2/this_col2   = the ) of the current s-exp.
    "
    
    " so we can get back.
    silent! norm! ma
    let [b, this_line1, this_col1, o] = getpos('.')

    " where does the *current* s-exp end?
    silent! norm! %
    let [b, this_line2, this_col2, o] = getpos('.')
    silent! norm! %

    " where does the previous s-exp end?
    call Sexp_Previous()
    silent! norm! mb

    let [b, prev_line1, prev_col1, o] = getpos('.')
    silent! norm! %
    let [b, prev_line2, prev_col2, o] = getpos('.')

    if (prev_line2 == this_line2 && prev_col2 > this_col2) || (prev_line2 > this_line2)
        " For now, just do nothing
        echom "Trying to transpose s-exp backwards with parent."
        return
    endif

    " --------------------------------------------------------

    " get the s-exps
    silent! norm! `a
    silent! norm! "ayab
    silent! norm! `b
    silent! norm! "byab

    " copy and replace current s-exp with whitespace
    let @c = Fill(" ", len(@b))
    let @d = Fill(" ", len(@a))

    silent! norm! `a"_dab
    silent! norm! `a"cP

    silent! norm! `b"_dab
    silent! norm! `b"dP

    if this_line1 == prev_line1

        let diff = len(@a) - len(@b)
        if diff > 0
            let movement = ''.diff.'l'
        elseif diff < 0
            let movement = ''.(-diff).'h'
        else
            let movement = ''
        endif

        silent! norm! `b"aPl
        silent! exe 'norm! '.len(@a).'x'

        silent! exe 'norm! `a'.movement.'"bPl'
        silent! exe 'norm! '.len(@b).'x'
        
        silent! norm! `b
    else
        " different lines, so a simple paste will do

        silent! norm! `a"bP
        silent! exe 'norm! l'.len(@a).'x'
        silent! norm! `b"aP
        silent! exe 'norm! l'.len(@b).'x'
        silent! norm! `b
    endif

    silent! let @* = regs
endfun

fun! Sexp_MoveForward()
    " Inside an s-exp?
    let [l, c] = searchpairpos('(', '', ')', 'bcnW')
    if l == 0 || c == 0
        " Nope, 
        return
    endif

    silent! let registers = @*

    " mark the start of this s-exp
    silent! norm! yl
    if @0 != "("
        call Sexp_Previous()
    endif

    " copy and replace current s-exp with whitespace
    silent! norm! ma
    let [b, line1, c, o] = getpos('.')

    silent! norm! "adab
    let @c = Fill(" ", len(@a))
    silent! norm! "cP

    " same thing with next.
    call Sexp_Next()
    let [b, line2, c, o] = getpos('.')

    silent! norm! mb
    silent! norm! "bdab
    let @c = Fill(" ", len(@b))
    silent! norm! "cP

    if line1 == line2
        " second position will be offset by pasting a s-exp
        " of a different size than the first.
        if len(@a) < len(@b)
            let movement = (len(@b)-len(@a))."l"
        elseif len(@a) > len(@b)
            let movement = (len(@a)-len(@b))."h"
        else
            let movement = ""
        endif

        echo "movement = ".movement

        " insert second s-exp at first position
        silent! norm! `a"bP

        " adjust first s-exp's insert point at second position
        silent! exe 'norm! `b'.movement
        silent! norm! "aP

        " remove the extra spacing inserted for cursor position
        " adjustment
        silent! exe 'norm! l'.(len(@a)+len(@b)).'x'
        silent! exe 'norm! `b'.movement
    else
        " different lines, so a simple paste will do

        silent! norm! `a"bP
        silent! exe 'norm! l'.len(@a).'x'
        silent! norm! `b"aP
        silent! exe 'norm! l'.len(@b).'x'
        silent! norm! `b
    endif

    silent! let @* = registers
endfun

fun! Fill(c, n)
    let s = ""
    let n = a:n
    while n > 0
        let s = s.a:c
        let n = n-1
    endwhile
    return s
endfun

