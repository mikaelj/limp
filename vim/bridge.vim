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
" only do these things once

let s:Limp_location = expand("$LIMPRUNTIME")

" prefix for the pipe used for communication
let s:limp_bridge_channel_base = $HOME . "/.limp_bridge_channel-"
let s:limp_bridge_connected=0
exe "setlocal complete+=s" . s:Limp_location . "/vim/thesaurus"

"-------------------------------------------------------------------
" talk to multiple Lisps using LimpBridge_connect()
"-------------------------------------------------------------------
fun! LimpBridge_complete_lisp(A,L,P)
    let prefix = s:limp_bridge_channel_base
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

        let s:limp_bridge_channel = s:limp_bridge_channel_base.name.".".pid
    else
        let s:limp_bridge_channel = s:limp_bridge_channel_base
        let name = input("Connect to [boot new]: ", "", "customlist,LimpBridge_complete_lisp")
        if name == ""
            return -1
        endif
        let s:limp_bridge_channel .= name
        if 0 == filewritable(s:limp_bridge_channel) "|| s:limp_bridge_channel = s:limp_bridge_channel_base
            echom "Not a Limp channel."
            return 0
        endif
    endif
    " extract the PID from format: foo.104982
    " (backward from screen sty naming to ease tab completion)
    
    " bridge id is the file used for communication between Vim and screen
    let s:limp_bridge_id = strpart(s:limp_bridge_channel, strlen(s:limp_bridge_channel_base))

    " bridge screenid is the screen in which the Lisp is running
    let s:limp_bridge_screenid = s:limp_bridge_id[strridx(s:limp_bridge_id, '.')+1:]
    "let s:limp_bridge_scratch = $HOME . "/.limp_bridge_scratch-" . s:limp_bridge_id
    let s:limp_bridge_test = $HOME . '/.limp_bridge_test-' . s:limp_bridge_id

    silent exe "new" s:limp_bridge_channel
        if exists( "#BufEnter#*.lisp#" )
            doauto BufEnter x.lisp
        endif
        setlocal syntax=lisp
        " XXX: in ViLisp, buftype=nowrite, but w/ limp_bridge_channel, vim
        " complains about the file being write-only.
        "setlocal buftype=nowrite
        setlocal bufhidden=hide
        setlocal nobuflisted
        setlocal noswapfile
    hide

    silent exe "new" s:limp_bridge_test
        if exists( "#BufEnter#*.lisp#" )
            doauto BufEnter x.lisp
        endif
        setlocal syntax=lisp
        " setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal nobuflisted
        " setlocal noswapfile
    hide

    " hide from the user that we created and deleted (hid, really) a couple of
    " buffers
    "normal! 
    redraw

    let s:limp_bridge_connected=1

    echom "Welcome to Limp. May your journey be pleasant."

    return 1
endfun

fun! LimpBridge_connection_status()
    if s:limp_bridge_connected == 1
        return "Connected to ".s:limp_bridge_id
    else
        return "Disconnected"
    endif
endfun

fun! LimpBridge_disconnect()
    let s:limp_bridge_connected = 0
    let s:limp_bridge_id = "<disconnected>"
endfun

"
" optionally, specify the path of the core to save to
"
fun! LimpBridge_quit_lisp(...)
    " we were given a file
    if a:0 == 1 && a:1 != ""
        let core = a:1
        call LimpBridge_send_to_lisp("(sb-ext:save-lisp-and-die \"".core."\")\n")
        echom "Lisp ".s:limp_bridge_id." is gone, core saved to ".core."."
    else
        call LimpBridge_send_to_lisp("(sb-ext:quit)\n")
        echom "Lisp ".s:limp_bridge_id." is gone."
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
        if stridx(status, s:limp_bridge_screenid) == -1
            call LimpBridge_disconnect()
            return
        endif
        let cmd = "screen -x ".s:limp_bridge_screenid
        if has("gui")
            let cmd = "xterm -e " . cmd . " &"
        endif
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
    autocmd BufLeave .LimpBridge_* setlocal nobuflisted
    autocmd BufLeave *.lisp let g:limp_bridge_last_lisp = bufname( "%" )
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
      exe "hide bu" s:limp_bridge_channel
      exe "%d"
      normal! 1G

      " tried append() -- doesn't work the way I need it to
      let old_l = @l
      let @l = a:sexp
      normal! "lP
      let @l = old_l

      silent exe 'w!'
      call system('screen -x '.s:limp_bridge_screenid.' -p 0 -X eval "readbuf" "paste ."')
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
  call LimpBridge_send_sexp_to_buffer( LimpBridge_yank( "%" ), s:limp_bridge_test )

  call LimpBridge_goto_pos( pos )
endfunction

function! LimpBridge_stuff_top_form()
  " save position
  let pos = LimpBridge_get_pos()

  " find & yank top-level s-exp
  silent! exec "normal! 99[("
  call LimpBridge_send_sexp_to_buffer( LimpBridge_yank( "%" ), s:limp_bridge_test )

  call LimpBridge_goto_pos( pos )
endfunction

function! LimpBridge_hyperspec(type, make_page)
  " get current word under cursor
  let word = expand( "<cword>" )
  let cmd = "! perl " . s:Limp_location . "/bin/limp-hyperspec.pl"
  let cmd = cmd . " " . a:type . " " . a:make_page . " '" .  word . "'"
  silent! exe cmd
  redraw!
endfunction


"-------------------------------------------------------------------
" plugin <-> function mappings
"-------------------------------------------------------------------

nnoremap <buffer> <unique> <Plug>LimpBootConnectDisplay  :call LimpBridge_boot_or_connect_or_display()<CR>
nnoremap <buffer> <unique> <Plug>LimpDisconnect          :call LimpBridge_disconnect()<CR>
nnoremap <buffer> <unique> <Plug>LimpShutdownLisp        :call LimpBridge_shutdown_lisp()<CR>

nnoremap <buffer> <unique> <Plug>EvalTop        :call LimpBridge_eval_top_form()<CR>
nnoremap <buffer> <unique> <Plug>EvalCurrent    :call LimpBridge_eval_current_form()<CR>
nnoremap <buffer> <unique> <Plug>EvalExpression :call LimpBridge_prompt_eval_expression()<CR>

vnoremap <buffer> <unique> <Plug>EvalBlock      :call LimpBridge_eval_block()<cr>

nnoremap <buffer> <unique> <Plug>AbortReset     :call LimpBridge_send_to_lisp( "ABORT\n" )<CR>
nnoremap <buffer> <unique> <Plug>AbortInterrupt :call LimpBridge_send_to_lisp( "" )<CR>

nnoremap <buffer> <unique> <Plug>TestCurrent    :call  LimpBridge_stuff_current_form()<CR>
nnoremap <buffer> <unique> <Plug>TestTop        :call  LimpBridge_stuff_top_form()<CR>

nnoremap <buffer> <unique> <Plug>LoadThisFile    :call LimpBridge_send_to_lisp( "(load \"" . expand( "%:p" ) . "\")\n")<CR>
nnoremap <buffer> <unique> <Plug>LoadAnyFile     :call LimpBridge_send_to_lisp( "(load \"" . expand( "%:p:r" ) . "\")\n")<CR>

nnoremap <buffer> <unique> <Plug>CompileFile        :call LimpBridge_send_to_lisp("(compile-file \"".expand("%:p")."\")\n")<CR>
nnoremap <buffer> <unique> <Plug>CompileAndLoadFile <Plug>CompileFile<Plug>LoadAnyFile

" Goto Test Buffer:
" Goto Split:         split current buffer and goto test buffer
nnoremap <buffer> <unique> <Plug>GotoTestBuffer           :call LimpBridge_goto_buffer_or_window(g:limp_bridge_test)<CR>
nnoremap <buffer> <unique> <Plug>GotoTestBufferAndSplit   :sb <bar> call LimpBridge_goto_buffer_or_window(g:limp_bridge_test)<CR>

" Goto Last:          return to g:limp_bridge_last_lisp, i.e. last buffer
nnoremap <buffer> <unique> <Plug>GotoLastLispBuffer   :call LimpBridge_goto_buffer_or_window(g:limp_bridge_last_lisp)<CR>

" HyperSpec:
nnoremap <buffer> <unique> <Plug>HyperspecExact    :call LimpBridge_hyperspec("exact", 0)<CR>
nnoremap <buffer> <unique> <Plug>HyperspecPrefix   :call LimpBridge_hyperspec("prefix", 1)<CR>
nnoremap <buffer> <unique> <Plug>HyperspecSuffix   :call LimpBridge_hyperspec("suffix", 1)<CR>
nnoremap <buffer> <unique> <Plug>HyperspecGrep             :call LimpBridge_hyperspec("grep", 1)<CR>
nnoremap <buffer> <unique> <Plug>HyperspecFirstLetterIndex :call LimpBridge_hyperspec("index", 0)<CR>
nnoremap <buffer> <unique> <Plug>HyperspecFullIndex   :call LimpBridge_hyperspec("index-page", 0)<CR>

" Help Describe:      ask Lisp about the current symbol
nnoremap <buffer> <unique> <Plug>HelpDescribe   :call LimpBridge_send_to_lisp("(describe '".expand("<cword>").")")<CR>

