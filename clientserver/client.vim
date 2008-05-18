" client.vim
"
" $ vim --servername client
" :source client.vim
" :Tool "hello, world"
" :messages

"Get to know each other 
call remote_expr("SERVER","1","serverid") 

augroup server 
  au! 
  "Do something with the reply 
  au RemoteReply * echom remote_read(g:serverid) 
augroup END 

"Send messages via SERVER 
com! -nargs=* Server :call server2client(g:serverid,<q-args>)

