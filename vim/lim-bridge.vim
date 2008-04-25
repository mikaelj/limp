" 
" lim/vim/lim-bridge.vim
"
" URL:
" http://mikael.jansson.be/hacking
"
" Description:
" Handle communication between Vim and Lisp, including boot, connect and
" display. Relies on 'lisp.sh' from the Lim package.
"
" Version:
" 0.2
"
" Date:
" 2008-04-25
"
" Authors:
" Mikael Jansson <mail@mikael.jansson.be>
" Larry Clapp <vim@theclapp.org>

" Changelog:
" 2008-08-25 by Mikael Jansson <mail@mikael.jansson.be>
" * Now boots a new Lisp or connects to an existing via screen.
"   No longer needs the funnel (although it does need a file to read to/from
"   screen: it doesn't seem as if 'stuff' can handle very large amounts of
"   texts)
"
" 2008-08-18 by Mikael Jansson <mail@mikael.jansson.be>
" * Tab-completed prompt that lets you choose the Lisp process to connect to.
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
fun! LimBridge_complete_lisp(A,L,P)
    let prefix = g:lim_bridge_channel_base
    echom "ls -1 ".prefix."*"
    let output = system("ls -1 ".prefix."*")
    if stridx(output, prefix."*") >= 0
        echom "No Lisps started yet?"
        return
    endif
    let files = split(output, "\n")
    let names = []
    for f in files
        let names += [f[strlen(prefix):]]
    endfor
    return names
endfun

" optionally specify the screen id to connect to
fun! LimBridge_connect(...)
    if a:0 == 1 && a:1 != ""
        " format: 7213.lim_listener-foo
        let pid = a:1[:stridx(a:1, '.')-1]
        let fullname = a:1[stridx(a:1, '.')+1:]
        let name = fullname[strlen("lim_listener-"):]

        let g:lim_bridge_channel = g:lim_bridge_channel_base.name.".".pid
    else
        "let s:lim_bridge_channel = input("Lisp? ", g:lim_bridge_channel_base, "file")
        let g:lim_bridge_channel = g:lim_bridge_channel_base
        let g:lim_bridge_channel .= input("Lisp? ", "", "customlist,LimBridge_complete_lisp")
        if 0 == filewritable(g:lim_bridge_channel) "|| g:lim_bridge_channel = g:lim_bridge_channel_base
            echom "Not a channel."
            return
        endif
    endif
    " extract the PID from format: foo.104982
    " (backward from screen sty naming to ease tab completion)
    
    " bridge id is the file used for communication between Vim and screen
    let g:lim_bridge_id = strpart(g:lim_bridge_channel, strlen(g:lim_bridge_channel_base))

    " bridge screenid is the screen in which the Lisp is running
    let g:lim_bridge_screenid = g:lim_bridge_id[strridx(g:lim_bridge_id, '.')+1:]
    "let g:lim_bridge_scratch = $HOME . "/.lim_bridge_scratch-" . g:lim_bridge_id
    let g:lim_bridge_test = $HOME . '/.lim_bridge_test-' . g:lim_bridge_id

    silent exe "new" g:lim_bridge_channel
        if exists( "#BufRead#*.lsp#" )
            doauto BufRead x.lsp
        endif
        set syntax=lisp
        " XXX: in ViLisp, buftype=nowrite, but w/ lim_bridge_channel, vim
        " complains about the file being write-only.
        "set buftype=nowrite
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
    "normal! 
    redraw

    let s:lim_bridge_connected=1

    echom "Welcome to Lim. May your journey be pleasant."
endfun

"
" when not connected, start new or connect to existing
" otherwise, switch to Lisp (screen)
fun! LimBridge_boot_or_connect_or_display()
    if s:lim_bridge_connected
        echom 'screen -x '.g:lim_bridge_screenid
        let cmd="screen -x ".g:lim_bridge_screenid
        silent exe "!".cmd
        redraw!
    else
        let name = input("Name the new Lisp [blank to connect to existing]: ")
        if name == ""
            call LimBridge_connect()
        else
            echom "Booting..."
            let sty = system("/home/mikaelj/hacking/lim/trunk/startlisp.sh -b ".name)
            call LimBridge_connect(sty)
        endif
  endif
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

  silent exe "hide bu" bufname
  silent exe "normal! " . l_top . "Gzt" . l_cur . "G" . c_cur . "|"
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
  

" destroys contents of LimBridge_channel buffer
function! LimBridge_send_to_lisp( sexp )
  if a:sexp == ''
    return
  endif

  if !s:lim_bridge_connected
    echom "Not connected to Lisp!"
    return
  endif    

  let p = LimBridge_get_pos()

  " goto LimBridge_channel, delete it, put s-exp, write it to lisp
  exe "hide bu" g:lim_bridge_channel
  exe "%d"
  normal! 1G

  " tried append() -- doesn't work the way I need it to
  let old_l = @l
  let @l = a:sexp
  normal! "lP
  let @l = old_l

  silent exe 'w!'

  "exe 'w! '.g:lim_bridge_channel
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

