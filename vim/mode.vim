" 
" limp/vim/mode.vim
"
" URL:
" http://mikael.jansson.be
"
" Description:
" Lisp-mode specific functions 
"
" Authors:
" Mikael Jansson <mail@mikael.jansson.be>
"
"Eval (say-hello 'mikael)
command! -buffer -nargs=* Eval silent call LimpBridge_send_to_lisp(<q-args>)

let b:listener_always_open_window=0
let b:listener_keep_open=0

let g:lisp_mode_active = 0
fun! LimpMode_start()
    if g:lisp_mode_active
        return
    endif
    let g:lisp_mode_active = 1
    "-------------------------------------------------------------------
    " coloring
    "-------------------------------------------------------------------
    let g:lisp_rainbow=1

    set t_Co=256
    if !exists("g:colors_name")
        colorscheme desert256
    endif

    hi Brackets      ctermbg=53 ctermfg=white 
    hi BracketsBlock ctermbg=235 guibg=lightgray
    hi StatusLine    ctermbg=white ctermfg=160
    hi StatusLineNC  ctermbg=black ctermfg=gray
    hi Pmenu         ctermbg=53 ctermfg=255
    hi PmenuSel      ctermbg=255 ctermfg=53

    "
    " set all parens to gray
    "
    hi hlLevel0 ctermfg=238
    hi hlLevel1 ctermfg=238
    hi hlLevel2 ctermfg=238
    hi hlLevel3 ctermfg=238
    hi hlLevel4 ctermfg=238
    hi hlLevel5 ctermfg=238
    hi hlLevel6 ctermfg=238
    hi hlLevel7 ctermfg=238
    hi hlLevel8 ctermfg=238
    hi hlLevel9 ctermfg=238
    hi hlLevel10 ctermfg=238
    hi hlLevel11 ctermfg=238

    call LimpHighlight_start()
    call AutoClose_start()

    " for whatever reason, nocursorline isn't set after pressing F12... (i.e.,
    " switching back to the buffer)
    setlocal nocursorline
endfun

fun! LimpMode_stop()
    let g:lisp_mode_active = 0
    call LimpHighlight_stop()
    call AutoClose_stop()
endfun

augroup LimpMode
    au!
    au BufEnter * :if &filetype == "lisp" | call LimpMode_start() | endif
    au BufLeave * :if &filetype == "lisp" | call LimpMode_stop() | endif
augroup END


"-------------------------------------------------------------------
" init filetype plugin
"-------------------------------------------------------------------
syntax on
setlocal nocompatible nocursorline
setlocal lisp syntax=lisp
setlocal ls=2 bs=2 si et sw=2 ts=2 tw=0 
setlocal statusline=%<%f\ \(%{LimpBridge_connection_status()}\)\ %h%m%r%=%-14.(%l,%c%V%)\ %P\ of\ %L\ \(%.45{getcwd()}\)
setlocal iskeyword=&,*,+,45,/,48-57,:,<,=,>,@,A-Z,a-z,_
setlocal cpoptions=-mp
setlocal foldmethod=marker foldmarker=(,) foldminlines=1


" This allows gf and :find to work. Fix path to your needs
setlocal suffixesadd=.lisp,cl path=/home/mikael/hacking/lisp/**

" This allows [d [i [D [I work across files if an ASDF buffer is opened
" If I used load, it would be there too.
setlocal include=(:file\

"-------------------------------------------------------------------
" reset to previous values
"-------------------------------------------------------------------

let s:save_cpo = &cpo
set cpo&vim

let b:undo_ftplugin = "setlocal syntax< lisp< ls< bs< si< et< sw< "
    \ . "ts< tw< complete< nocursorline< nocompatible< statusline< iskeyword< "
    \ . "cpoptions< foldmethod< foldmarker< foldminlines< "
    \ . "suffixesadd< path< include< "

let &cpo = s:save_cpo
unlet s:save_cpo


"------------- boot!

call LimpMode_start()

