
" Last updated: Sun Oct 02 08:30:51 EDT 2005 

" By Larry Clapp <vim@theclapp.org>
" Copyright 2002
" $Header: /home/lmc/lisp/briefcase/VIlisp/devel/RCS/VIlisp.vim,v 1.5 2002/06/11 02:38:39 lmc Exp $
"
" * 2008-08-18 by Mikael Jansson <mail@mikael.jansson.be>
"   Tab-completed prompt that lets you choose the Lisp process to connect to.
"   Moved the startup to before the loaded check.

"-------------------------------------------------------------------
" startup
"-------------------------------------------------------------------
if exists( "g:lim_bridge_loaded" )
  finish
else
  let g:lim_bridge_loaded = 1
endif

" only do this once
let s:lim_bridge_connected=0
let s:LimBridge_location = expand( "<sfile>:h" )
exe "set complete+=s" . s:LimBridge_location . "/lisp-thesaurus"

"-------------------------------------------------------------------
" talk to multiple Lisps using LimBridge_connect()
"-------------------------------------------------------------------
fun! LimBridge_connect()
    let s:lim_bridge_channel = input("Lisp? ", g:lim_bridge_channel_base, "file")
    let g:lim_bridge_id = strpart(s:lim_bridge_channel, strlen(g:lim_bridge_channel_base))
    " extract the PID from "foobar.whatever.104982"
    let g:lim_bridge_screenid = g:lim_bridge_id[strridx(g:lim_bridge_id, '.')+1:]
    let g:lim_bridge_scratch = $HOME . "/.lim_bridge_scratch-" . g:lim_bridge_id
    let g:lim_bridge_test = $HOME . '/.lim_bridge_test-' . g:lim_bridge_id

    silent exe "new" g:lim_bridge_scratch
        if exists( "#BufRead#*.lsp#" )
            doauto BufRead x.lsp
        endif
        set syntax=lisp
        set buftype=nowrite
        set bufhidden=hide
        set nobuflisted
        set noswapfile
    hide

    silent exe "new" g:lim_bridge_test
        if exists( "#BufRead#*.lsp#" )
            doauto BufRead x.lsp
        endif
        set syntax=lisp
        " set buftype=nofile
        set bufhidden=hide
        set nobuflisted
        " set noswapfile
    hide

    " hide from the user that we created and deleted (hid, really) a couple of
    " buffers
    normal! 

    let s:lim_bridge_connected=1
endfun

fun! LimBridge_boot_lisp()
    let name = input("Name of Lisp? ")
    if name == ""
        echom "No name given, bailing out."
        return
    endif
"call system("bash -c \"/home/mikaelj/hacking/lim/trunk/startlisp.sh -b ".name."\"")
exe '!/home/mikaelj/hacking/lim/trunk/startlisp.sh -b '.name
endfun

augroup LimBridge
    au!
    autocmd BufLeave .LimBridge_* set nobuflisted
    autocmd BufLeave *.lsp,*.lisp let s:lim_bridge_last_lisp = bufname( "%" )
augroup END

"-------------------------------------------------------------------
" library
"-------------------------------------------------------------------
function! LimBridge_goto_buffer_or_window( buff )
  if -1 == bufwinnr( a:buff )
    exe "hide bu" a:buff
  else
    exe bufwinnr( a:buff ) . "wincmd w"
  endif
endfunction


function! LimBridge_get_pos()
  " what buffer are we in?
  let bufname = bufname( "%" )

  " get current position
  let c_cur = virtcol( "." )
  let l_cur = line( "." )
  normal! H
  let l_top = line( "." )

  let pos = bufname . "|" . l_top . "," . l_cur . "," . c_cur

  " go back
  exe "normal! " l_cur . "G" . c_cur . "|"

  return( pos )
endfunction


function! LimBridge_goto_pos( pos )
  let mx = '\(\f\+\)|\(\d\+\),\(\d\+\),\(\d\+\)'
  let bufname = substitute( a:pos, mx, '\1', '' )
  let l_top = substitute( a:pos, mx, '\2', '' )
  let l_cur = substitute( a:pos, mx, '\3', '' )
  let c_cur = substitute( a:pos, mx, '\4', '' )

  exe "hide bu" bufname
  exe "normal! " . l_top . "Gzt" . l_cur . "G" . c_cur . "|"
endfunction


function! LimBridge_yank( motion )
  let value = ''

  let p = LimBridge_get_pos()
  silent! exec 'normal!' a:motion
  let new_p = LimBridge_get_pos()

  " did we move?
  if p != new_p
      " go back
      silent! exec 'normal!' a:motion

      let old_l = @l
      exec 'normal! "ly' . a:motion
      let value = @l
      let @l = old_l
  endif

  call LimBridge_goto_pos( p )

  return( value )
endfunction


" copy an expression to a buffer
function! LimBridge_send_sexp_to_buffer( sexp, buffer )
  let p = LimBridge_get_pos()

  " go to the given buffer, go to the bottom
  exe "hide bu" a:buffer
  silent normal! G

  " tried append() -- doesn't work the way I need it to
  let old_l = @l
  let @l = a:sexp
  silent exe "put l"
  " normal! "lp
  let @l = old_l

  call LimBridge_goto_pos( p )
endfunction
  

" destroys contents of LimBridge_scratch buffer
function! LimBridge_send_to_lisp( sexp )
  if a:sexp == ''
    return
  endif

  if !s:lim_bridge_connected
    echom "Not connected to Lisp!"
    return
  endif    

  let p = LimBridge_get_pos()

  " goto LimBridge_scratch, delete it, put s-exp, write it to lisp
  exe "hide bu" g:lim_bridge_scratch
  exe "%d"
  normal! 1G

  " tried append() -- doesn't work the way I need it to
  let old_l = @l
  let @l = a:sexp
  normal! "lP
  let @l = old_l

  exe 'w! '.s:lim_bridge_channel
  call system('screen -x '.g:lim_bridge_screenid.' -p 0 -X eval "readbuf" "paste ."')

  call LimBridge_goto_pos( p )
endfunction

function! LimBridge_prompt_eval_expression()
  let whatwhat = input("Eval: ")
  call LimBridge_send_to_lisp(whatwhat)
endfun


" Actually evals current top level form
function! LimBridge_eval_top_form()
  " save position
  let p = LimBridge_get_pos()

  silent! exec "normal! 99[("
  call LimBridge_send_to_lisp( LimBridge_yank( "%" ) )

  " fix cursor position, in case of error below
  call LimBridge_goto_pos( p )
endfunction


function! LimBridge_eval_current_form()
  " save position
  let pos = LimBridge_get_pos()

  " find & yank current s-exp
  normal! [(
  let sexp = LimBridge_yank( "%" )
  call LimBridge_send_to_lisp( sexp )
  call LimBridge_goto_pos( pos )
endfunction


function! LimBridge_eval_block() range
  " save position
  let pos = LimBridge_get_pos()

  " yank current visual block
  let old_l = @l
  '<,'> yank l
  let sexp = @l
  let @l = old_l

  call LimBridge_send_to_lisp( sexp )
  call LimBridge_goto_pos( pos )
endfunction


function! LimBridge_stuff_current_form()
  " save position
  let pos = LimBridge_get_pos()

  " find & yank current s-exp
  normal! [(
  call LimBridge_send_sexp_to_buffer( LimBridge_yank( "%" ), g:lim_bridge_test )

  call LimBridge_goto_pos( pos )
endfunction


function! LimBridge_hyperspec(type, make_page)
  " get current word under cursor
  let word = expand( "<cword>" )
  let cmd = "! perl " . s:LimBridge_location . "/LimBridge-hyperspec.pl "
  let cmd = cmd . a:type . " " . a:make_page . " '" .  word . "'"
  silent! exe cmd
  redraw!
endfunction



"-------------------------------------------------------------------
" keymap
"-------------------------------------------------------------------

"
" interact with the Lisp listener
"

