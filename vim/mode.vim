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
" Changelog:
" 2008-04-20
" * Initial version.

"-------------------------------------------------------------------
" key bindings
"-------------------------------------------------------------------

nmap <buffer> <unique> <F12>                <Plug>LimpBootConnectDisplay
nmap <buffer> <unique> <C-F12>              <Plug>LimpDisconnect
nmap <buffer> <unique> <S-F12>              <Plug>LimpShutdownLisp

" Eval Top:           send top-level s-exp to Lisp
" Eval Current:       send current s-exp to Lisp
" Eval Expression:    send arbitrary code to Lisp
nmap <buffer> <unique> <LocalLeader>et      <Plug>EvalTop
nmap <buffer> <unique> <LocalLeader>ec      <Plug>EvalCurrent
nmap <buffer> <unique> <LocalLeader>ex      <Plug>EvalExpression

" Eval Block:         visual mode
vmap <buffer> <unique> <LocalLeader>et      <Plug>EvalBlock
vmap <buffer> <unique> <LocalLeader>ec      <Plug>EvalBlock
vmap <buffer> <unique> <LocalLeader>ex      <Plug>EvalBlock

" SBCL Abort Reset:   abort from the debugger
nmap <buffer> <unique> <LocalLeader>ar      <Plug>AbortReset 

" Abort Interrupt:    send ^C to interpreter
nmap <buffer> <unique> <LocalLeader>ai      <Plug>AbortInterrupt

" Test Current:       copy current s-exp to test buffer
" Test Top:           copy top s-exp to test buffer
nmap <buffer> <unique> <LocalLeader>tc      <Plug>TestCurrent
nmap <buffer> <unique> <LocalLeader>tt      <Plug>TestTop

" Load File:          load /this/ file into Lisp
" Load Any File:      load whichever version of this file (.lisp not given)
nmap <buffer> <unique> <LocalLeader>lf      <Plug>LoadThisFile
nmap <buffer> <unique> <LocalLeader>la      <Plug>LoadAnyFile 

" Compile File:       compile the current file
" Compile Load File:  compile, then load the current file
nmap <buffer> <unique> <LocalLeader>cf      <Plug>CompileFile
nmap <buffer> <unique> <LocalLeader>cl      <Plug>CompileAndLoadFile 

" Goto Test Buffer:
" Goto Split:         split current buffer and goto test buffer
nmap <buffer> <unique> <LocalLeader>gt      <Plug>GotoTestBuffer
nmap <buffer> <unique> <LocalLeader>gs      <Plug>GotoTestBufferAndSplit

" Goto Last:          return to last Lisp buffer
nmap <buffer> <unique> <LocalLeader>gl      <Plug>GotoLastLispBuffer 

" HyperSpec:
nmap <buffer> <unique> <LocalLeader>he      <Plug>HyperspecExact
nmap <buffer> <unique> <LocalLeader>hp      <Plug>HyperspecPrefix
nmap <buffer> <unique> <LocalLeader>hs      <Plug>HyperspecSuffix
nmap <buffer> <unique> <LocalLeader>hg      <Plug>HyperspecGrep
nmap <buffer> <unique> <LocalLeader>hi      <Plug>HyperspecFirstLetterIndex
nmap <buffer> <unique> <LocalLeader>hI      <Plug>HyperspecFullIndex
nmap <buffer>          K                    <Plug>HyperspecExact

" Help Describe:      ask Lisp about the current symbol
nmap <buffer> <unique> <LocalLeader>hd      <Plug>HelpDescribe

