" 
" limp/vim/keys.vim
"
" Description:
" Limp key bindings
"
" Authors:
" Mikael Jansson <mail@mikael.jansson.be>
"

nmap <buffer> <F12>                <Plug>LimpBootConnectDisplay
nmap <buffer> <C-F12>              <Plug>LimpDisconnect
nmap <buffer> <S-F12>              <Plug>LimpShutdownLisp

" Eval Top:           send top-level s-exp to Lisp
" Eval Current:       send current s-exp to Lisp
" Eval Expression:    send arbitrary code to Lisp
nmap <buffer> <LocalLeader>et      <Plug>EvalTop
nmap <buffer> <LocalLeader>ec      <Plug>EvalCurrent
nmap <buffer> <LocalLeader>ex      <Plug>EvalExpression

" Eval Block:         visual mode
vmap <buffer> <LocalLeader>et      <Plug>EvalBlock
vmap <buffer> <LocalLeader>ec      <Plug>EvalBlock
vmap <buffer> <LocalLeader>ex      <Plug>EvalBlock

" SBCL Abort Reset:   abort from the debugger
nmap <buffer> <LocalLeader>ar      <Plug>AbortReset 

" Abort Interrupt:    send ^C to interpreter
nmap <buffer> <LocalLeader>ai      <Plug>AbortInterrupt

" Test Current:       copy current s-exp to test buffer
" Test Top:           copy top s-exp to test buffer
nmap <buffer> <LocalLeader>tc      <Plug>TestCurrent
nmap <buffer> <LocalLeader>tt      <Plug>TestTop

" Load File:          load /this/ file into Lisp
" Load Any File:      load whichever version of this file (.lisp not given)
nmap <buffer> <LocalLeader>lf      <Plug>LoadThisFile
nmap <buffer> <LocalLeader>la      <Plug>LoadAnyFile 

" Compile File:       compile the current file
" Compile Load File:  compile, then load the current file
nmap <buffer> <LocalLeader>cf      <Plug>CompileFile
nmap <buffer> <LocalLeader>cl      <Plug>CompileAndLoadFile 

" Goto Test Buffer:
" Goto Split:         split current buffer and goto test buffer
nmap <buffer> <LocalLeader>gt      <Plug>GotoTestBuffer
nmap <buffer> <LocalLeader>gs      <Plug>GotoTestBufferAndSplit

" Goto Last:          return to last Lisp buffer
nmap <buffer> <LocalLeader>gl      <Plug>GotoLastLispBuffer 

" HyperSpec:
nmap <buffer> <LocalLeader>he      <Plug>HyperspecExact
nmap <buffer> <LocalLeader>hp      <Plug>HyperspecPrefix
nmap <buffer> <LocalLeader>hs      <Plug>HyperspecSuffix
nmap <buffer> <LocalLeader>hg      <Plug>HyperspecGrep
nmap <buffer> <LocalLeader>hi      <Plug>HyperspecFirstLetterIndex
nmap <buffer> <LocalLeader>hI      <Plug>HyperspecFullIndex
nmap <buffer>          K                    <Plug>HyperspecExact

" Help Describe:      ask Lisp about the current symbol
nmap <buffer> <LocalLeader>hd      <Plug>HelpDescribe

" Mark Top:           mark visual block
nmap <buffer> <LocalLeader>mt      <Plug>MarkTop

" Format Current:     reindent/format
" Format Top:    
nmap <buffer> <LocalLeader>fc      <Plug>FormatCurrent
nmap <buffer> <LocalLeader>ft      <Plug>FormatTop

" Sexp Wrap: 	     wrap the current form in a list
" Sexp Peel:         peel a list off the current form
nmap <buffer> <LocalLeader>sw      <Plug>SexpWrap
nmap <buffer> <LocalLeader>sp      <Plug>SexpPeel

" Sexp Previous:    navigate to previous s-exp
" Sexp Next:        navigate to previous s-exp
nmap <buffer> (                    <Plug>SexpPrevious
nmap <buffer> )                    <Plug>SexpNext

" Sexp Move Back:       swap this and previous s-exp
" Sexp Move Forward:    swap this and next s-exp
nmap <buffer> {                    <Plug>SexpMoveBack
nmap <buffer> }                    <Plug>SexpMoveForward

" Sexp Comment:      comment all the way from the top level
nmap <buffer> <LocalLeader>sc      <Plug>SexpComment

" Sexp Comment Current:    comment current form
nmap <buffer> <LocalLeader>sC      <Plug>SexpCommentCurrent

