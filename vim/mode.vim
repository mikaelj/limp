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

fun! LimpMode_start()
    "-------------------------------------------------------------------
    " coloring
    "-------------------------------------------------------------------
    let g:lisp_rainbow=1

    if !exists("g:colors_name")
        set t_Co=256
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
    call LimpHighlight_stop()
    call AutoClose_stop()
endfun

augroup LimpMode
    au!
    au BufEnter * :if &filetype == "lisp" | call LimpMode_start() | endif
    au BufLeave * :if &filetype == "lisp" | call LimpMode_stop() | endif
augroup END

