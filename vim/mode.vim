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
command! -buffer -nargs=* Eval call LimpBridge_send_to_lisp(<q-args>)

let b:listener_always_open_window=0
let b:listener_keep_open=0

