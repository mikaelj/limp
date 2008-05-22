" server.vim
"
" $ vim --servername server
" :source server.vim
" :let data = ReceiveDataBlocking()
" :echo data

"Get to know each other 
call remote_expr("CLIENT","1","clientid") 

func! ReceiveDataBlocking() 
  "called from your tool, blocks till msg is available 
  return remote_read(g:clientid) 
endfun 

func! Reply(msg) 
  "called by the tool to reply 
  call server2client(g:clientid,a:msg) 
endfun

