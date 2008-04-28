" 
" limp/vim/bridge.vim
"
" URL:
" http://mikael.jansson.be/hacking
"
" Description:
" Handle communication between Vim and Lisp, including boot, connect and
" display. Relies on 'lisp.sh' from the Limp package.
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
" 2008-08-26 by Mikael Jansson <mail@mikael.jansson.be>
" * Optionally specify core at startup and exit.
"
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
if exists( "g:limp_bridge_loaded" )
  finish
else
  let g:limp_bridge_loaded = 1
endif

" only do these things once

" prefix for the pipe used for communication
let g:limp_bridge_channel_base = $HOME . "/.limp_bridge_channel-"
let s:limp_bridge_connected=0
let s:LimpBridge_location = expand("$LIMPRUNTIME")
exe "set complete+=s" . s:LimpBridge_location . "/vim/thesaurus"

"-------------------------------------------------------------------
" talk to multiple Lisps using LimpBridge_connect()
"-------------------------------------------------------------------
fun! LimpBridge_complete_lisp(A,L,P)
    let prefix = g:limp_bridge_channel_base
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
"
" return values:
"
" -1 if user didn't want to connect
" 0 if connection wasn't possible
" 1 if the user did connect
" 2 if the user was already connected
"
fun! LimpBridge_connect(...)
    if s:limp_bridge_connected == 1
        echom "Already to connected to Lisp!"
        return 2
    endif
    if a:0 == 1 && a:1 != ""
        " format: 7213.limp_listener-foo
        let pid = a:1[:stridx(a:1, '.')-1]
        let fullname = a:1[stridx(a:1, '.')+1:]
        let name = fullname[strlen("limp_listener-"):]

        let g:limp_bridge_channel = g:limp_bridge_channel_base.name.".".pid
    else
        let g:limp_bridge_channel = g:limp_bridge_channel_base
        let name = input("Connect to [boot new]: ", "", "customlist,LimpBridge_complete_lisp")
        if name == ""
            return -1
        endif
        let g:limp_bridge_channel .= name
        if 0 == filewritable(g:limp_bridge_channel) "|| g:limp_bridge_channel = g:limp_bridge_channel_base
            echom "Not a Limp channel."
            return 0
        endif
    endif
    " extract the PID from format: foo.104982
    " (backward from screen sty naming to ease tab completion)
    
    " bridge id is the file used for communication between Vim and screen
    let g:limp_bridge_id = strpart(g:limp_bridge_channel, strlen(g:limp_bridge_channel_base))

    " bridge screenid is the screen in which the Lisp is running
    let g:limp_bridge_screenid = g:limp_bridge_id[strridx(g:limp_bridge_id, '.')+1:]
    "let g:limp_bridge_scratch = $HOME . "/.limp_bridge_scratch-" . g:limp_bridge_id
    let g:limp_bridge_test = $HOME . '/.limp_bridge_test-' . g:limp_bridge_id

    silent exe "new" g:limp_bridge_channel
        if exists( "#BufRead#*.lsp#" )
            doauto BufRead x.lsp
        endif
        set syntax=lisp
        " XXX: in ViLisp, buftype=nowrite, but w/ limp_bridge_channel, vim
        " complains about the file being write-only.
        "set buftype=nowrite
        set bufhidden=hide
        set nobuflisted
        set noswapfile
    hide

    silent exe "new" g:limp_bridge_test
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

    let s:limp_bridge_connected=1

    echom "Welcome to Lim. May your journey be pleasant."

    return 1
endfun

fun! LimpBridge_connection_status()
    if s:limp_bridge_connected == 1
        return "Connected to ".g:limp_bridge_id
    else
        return "Disconnected"
    endif
endfun

fun! LimpBridge_disconnect()
    let s:limp_bridge_connected = 0
    let g:limp_bridge_id = "<disconnected>"
endfun

"
" optionally, specify the path of the core to save to
"
fun! LimpBridge_quit_lisp(...)
    " we were given a file
    if a:0 == 1 && a:1 != ""
        let core = a:1
        call LimpBridge_send_to_lisp("(sb-ext:save-lisp-and-die \"".core."\")\n")
        echom "Lisp ".g:limp_bridge_id." is gone, core saved to ".core."."
    else
        call LimpBridge_send_to_lisp("(sb-ext:quit)\n")
        echom "Lisp ".g:limp_bridge_id." is gone."
    endif
    call LimpBridge_disconnect()
endfun

fun! LimpBridge_shutdown_lisp()
    if s:limp_bridge_connected == 1
        let core = input("Name of core to save [none]: ", "", "file")
        call LimpBridge_quit_lisp(core)
    else
        echom "Not connected."
    endif
endfun

"
" when not connected, start new or connect to existing
" otherwise, switch to Lisp (screen)
fun! LimpBridge_boot_or_connect_or_display()
    if s:limp_bridge_connected
        " is it still running?
        let status = system("screen -ls")
        if stridx(status, g:limp_bridge_screenid) == -1
            call LimpBridge_disconnect()
            return
        endif
        let cmd = "screen -x ".g:limp_bridge_screenid
        silent exe "!".cmd
        redraw!
    else
        let what = LimpBridge_connect()
        if what <= 0
            " user didn't want to connect, let's boot!
            let name = input("Name the Lisp: ")
            if name == "" && a:0 == 1 && a:1 != ""
                " give up
                return
            endif

            let core = input("Path to core to boot [use system-default]: ", "", "file")
            let core_opt = ""
            if filereadable(core)
                let core_opt = "-c ".core
                echom "Booting ".core."..."
            else
                echom "Booting..."
            endif
            let sty = system("$LIMPRUNTIME/bin/lisp.sh ".core_opt." -b ".name)
            call LimpBridge_connect(sty)
        endif
  endif
endfun

augroup LimpBridge
    au!
    autocmd BufLeave .LimpBridge_* set nobuflisted
    autocmd BufLeave *.lsp,*.lisp let g:limp_bridge_last_lisp = bufname( "%" )
augroup END

"-------------------------------------------------------------------
" library
"-------------------------------------------------------------------
function! LimpBridge_goto_buffer_or_window( buff )
  if -1 == bufwinnr( a:buff )
    exe "hide bu" a:buff
  else
    exe bufwinnr( a:buff ) . "wincmd w"
  endif
endfunction


function! LimpBridge_get_pos()
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


function! LimpBridge_goto_pos( pos )
  let mx = '\(\f\+\)|\(\d\+\),\(\d\+\),\(\d\+\)'
  let bufname = substitute( a:pos, mx, '\1', '' )
  let l_top = substitute( a:pos, mx, '\2', '' )
  let l_cur = substitute( a:pos, mx, '\3', '' )
  let c_cur = substitute( a:pos, mx, '\4', '' )

  silent exe "hide bu" bufname
  silent exe "normal! " . l_top . "Gzt" . l_cur . "G" . c_cur . "|"
endfunction


function! LimpBridge_yank( motion )
  let value = ''

  let p = LimpBridge_get_pos()
  silent! exec 'normal!' a:motion
  let new_p = LimpBridge_get_pos()

  " did we move?
  if p != new_p
      " go back
      silent! exec 'normal!' a:motion

      let old_l = @l
      exec 'normal! "ly' . a:motion
      let value = @l
      let @l = old_l
  endif

  call LimpBridge_goto_pos( p )

  return( value )
endfunction


" copy an expression to a buffer
function! LimpBridge_send_sexp_to_buffer( sexp, buffer )
  let p = LimpBridge_get_pos()

  " go to the given buffer, go to the bottom
  exe "hide bu" a:buffer
  silent normal! G

  " tried append() -- doesn't work the way I need it to
  let old_l = @l
  let @l = a:sexp
  silent exe "put l"
  " normal! "lp
  let @l = old_l

  call LimpBridge_goto_pos( p )
endfunction
  

" destroys contents of LimpBridge_channel buffer
function! LimpBridge_send_to_lisp( sexp )
  if a:sexp == ''
    return
  endif

  if !s:limp_bridge_connected
    echom "Not connected to Lisp!"
    return
  endif    

  let p = LimpBridge_get_pos()

  " goto LimpBridge_channel, delete it, put s-exp, write it to lisp
  try
      exe "hide bu" g:limp_bridge_channel
      exe "%d"
      normal! 1G

      " tried append() -- doesn't work the way I need it to
      let old_l = @l
      let @l = a:sexp
      normal! "lP
      let @l = old_l

      silent exe 'w!'
      call system('screen -x '.g:limp_bridge_screenid.' -p 0 -X eval "readbuf" "paste ."')
  catch /^Vim:E211:/
      echom "Lisp is gone!"
      " file not available, Lisp disappeared
      call LimpBridge_disconnect()
  endtry

  call LimpBridge_goto_pos( p )
endfunction

function! LimpBridge_prompt_eval_expression()
  let whatwhat = input("Eval: ")
  call LimpBridge_send_to_lisp(whatwhat)
endfun


" Actually evals current top level form
function! LimpBridge_eval_top_form()
  " save position
  let p = LimpBridge_get_pos()

  silent! exec "normal! 99[("
  call LimpBridge_send_to_lisp( LimpBridge_yank( "%" ) )

  " fix cursor position, in case of error below
  call LimpBridge_goto_pos( p )
endfunction


function! LimpBridge_eval_current_form()
  " save position
  let pos = LimpBridge_get_pos()

  " find & yank current s-exp
  normal! [(
  let sexp = LimpBridge_yank( "%" )
  call LimpBridge_send_to_lisp( sexp )
  call LimpBridge_goto_pos( pos )
endfunction


function! LimpBridge_eval_block() range
  " save position
  let pos = LimpBridge_get_pos()

  " yank current visual block
  let old_l = @l
  '<,'> yank l
  let sexp = @l
  let @l = old_l

  call LimpBridge_send_to_lisp( sexp )
  call LimpBridge_goto_pos( pos )
endfunction


function! LimpBridge_stuff_current_form()
  " save position
  let pos = LimpBridge_get_pos()

  " find & yank current s-exp
  normal! [(
  call LimpBridge_send_sexp_to_buffer( LimpBridge_yank( "%" ), g:limp_bridge_test )

  call LimpBridge_goto_pos( pos )
endfunction

function! LimpBridge_stuff_top_form()
  " save position
  let pos = LimpBridge_get_pos()

  " find & yank top-level s-exp
  silent! exec "normal! 99[("
  call LimpBridge_send_sexp_to_buffer( LimpBridge_yank( "%" ), g:limp_bridge_test )

  call LimpBridge_goto_pos( pos )
endfunction

function! LimpBridge_hyperspec(type, make_page)
  " get current word under cursor
  let word = expand( "<cword>" )
  let cmd = "! perl " . s:LimpBridge_location . "/bin/lim-hyperspec.pl"
  let cmd = cmd . " " . a:type . " " . a:make_page . " '" .  word . "'"
  silent! exe cmd
  redraw!
endfunction

