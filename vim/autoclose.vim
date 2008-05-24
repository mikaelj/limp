" 
" limp/vim/autoclose.vim
"
" URL:
" http://mikael.jansson.be/hacking
"
" Description:
" AutoClose, closes what's opened.
"
" This plugin closes opened parenthesis, braces, brackets, quotes as you
" type them. As of 1.1, if you type the open brace twice ({{), the closing
" brace will be pushed down to a new line.
"
" You can enable or disable this plugin by typing \a (or <Leader>a if
" you've redefined your leader character) in normal mode. You'll also
" probably want to know you can type <C-V> (<C-Q> if mswin is set) and the next
" character you type doesn't have mappings applied. This is useful when you
" want to insert only an opening paren or something.
"
" Version:
" 0.2
"
" Date:
" September 20, 2007
"
" Authors:
" Karl Guertin <grayrest@gr.ayre.st>
" Mikael Jansson <mail@mikael.jansson.be>
"
" Changelog:
" 2008-04-20 by Mikael Jansson <mail@mikael.jansson.be>
" * Factored out start/stop functions.
" * Removed the default mappings to toggle autoclose
"
" 2007-09-20 by Karl Guertin <grayrest@gr.ayre.st>
"  1.1.2 -- Fixed a mapping typo and caught a double brace problem
"  1.1.1 -- Missed a bug in 1.1, September 19, 2007
"  1.1   -- When not inserting at the end, previous version would eat chars
"           at end of line, added double open->newline, September 19, 2007
"  1.0.1 -- Cruft from other parts of the mapping, knew I shouldn't have
"           released the first as 1.0, April 3, 2007

" Setup -----------------------------------------------------{{{1

let s:omni_active = 0
let s:cotstate = &completeopt

if !exists('g:autoclose_on')
    let g:autoclose_on = 0
endif

" assume everything has been defined already if one of the functions are
" defined.
if exists("*AutoClose_start")
    finish
endif

if !exists("*AutoClose_stop")
fun! AutoClose_stop()
    if g:autoclose_on
        iunmap "
        iunmap (
        iunmap )
        iunmap [
        iunmap ]
        iunmap {
        iunmap }
        iunmap <BS>
        iunmap <C-h>
        iunmap <Esc>
        ""iunmap <C-[>
        let g:autoclose_on = 0
    endif
endfun
endif

if !exists("*AutoClose_start")
fun! AutoClose_start()
    if !g:autoclose_on
        inoremap <silent> " <C-R>=<SID>QuoteDelim('"')<CR>
        inoremap <silent> ( (<C-R>=<SID>CloseStackPush(')')<CR>
        inoremap <silent> ) <C-R>=<SID>CloseStackPop(')')<CR>
        inoremap <silent> [ [<C-R>=<SID>CloseStackPush(']')<CR>
        inoremap <silent> ] <C-R>=<SID>CloseStackPop(']')<CR>
        inoremap <silent> { <C-R>=<SID>OpenSpecial('{','}')<CR>
        inoremap <silent> } <C-R>=<SID>CloseStackPop('}')<CR>
        inoremap <silent> <BS> <C-R>=<SID>OpenCloseBackspace()<CR>
        inoremap <silent> <C-h> <C-R>=<SID>OpenCloseBackspace()<CR>
        inoremap <silent> <Esc> <C-R>=<SID>CloseStackPop('')<CR><Esc>
        inoremap <silent> <C-[> <C-R>=<SID>CloseStackPop('')<CR><C-[>
        let g:autoclose_on = 1
    endif
endfunction
endif
let s:closeStack = []

" AutoClose Utilities -----------------------------------------{{{1
if !exists("*<SID>OpenSpecial")
function <SID>OpenSpecial(ochar,cchar) " ---{{{2
    let line = getline('.')
    let col = col('.') - 2
    "echom string(col).':'.line[:(col)].'|'.line[(col+1):]
    if a:ochar == line[(col)] && a:cchar == line[(col+1)] "&& strlen(line) - (col) == 2
        "echom string(s:closeStack)
        while len(s:closeStack) > 0
            call remove(s:closeStack, 0)
        endwhile
        return "\<esc>a\<CR>a\<CR>".a:cchar."\<esc>\"_xk$\"_xa"
    endif
    return a:ochar.<SID>CloseStackPush(a:cchar)
endfunction
endif

if !exists("*<SID>CloseStackPush")
function <SID>CloseStackPush(char) " ---{{{2
    "echom "push"
    let line = getline('.')
    let col = col('.')-2
    if (col) < 0
        call setline('.',a:char.line)
    else
        "echom string(col).':'.line[:(col)].'|'.line[(col+1):]
        call setline('.',line[:(col)].a:char.line[(col+1):])
    endif
    call insert(s:closeStack, a:char)
    "echom join(s:closeStack,'').' -- '.a:char
    return ''
endfunction
endif

if !exists("*<SID>CloseStackPop")
function <SID>CloseStackPop(char) " ---{{{2
    "echom "pop"
    if len(s:closeStack) == 0
        return a:char
    endif
    let popped = ''
    let lastpop = ''
    "echom join(s:closeStack,'').' || '.lastpop
    while len(s:closeStack) > 0 && ((lastpop == '' && popped == '') || lastpop != a:char)
        let lastpop = remove(s:closeStack,0)
        let popped .= lastpop
        "echom join(s:closeStack,'').' || '.lastpop.' || '.popped
    endwhile
    "echom ' --> '.popped
    let col = col('.') - 2
    let line = getline('.')
    let splits = split(line[:col],popped,1)
    "echom string(splits)
    "echom col.' '.line[(col+2):].' '.popped
    call setline('.',join(splits,popped).line[(col+strlen(popped)+1):])
    return popped
endfunction
endif

if !exists("*<SID>QuoteDelim")
function <SID>QuoteDelim(char) " ---{{{2
  let line = getline('.')
  let col = col('.')
  if line[col - 2] == "\\"
    "Inserting a quoted quotation mark into the string
    return a:char
  elseif line[col - 1] == a:char
    "Escaping out of the string
    return "\<C-R>=".s:SID()."CloseStackPop(\"\\".a:char."\")\<CR>"
  else
    "Starting a string
    return a:char."\<C-R>=".s:SID()."CloseStackPush(\"\\".a:char."\")\<CR>"
  endif
endfunction
endif

" The strings returned from QuoteDelim aren't in scope for <SID>, so I
" have to fake it using this function (from the Vim help, but tweaked)
"
if !exists("*s:SID")
function s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSID$')
endfun
endif

if !exists("*<SID>OpenCloseBackspace")
function <SID>OpenCloseBackspace() " ---{{{2
    "if pumvisible()
    "    pclose
    "    call <SID>StopOmni()
    "    return "\<C-E>"
    "else
        let curline = getline('.')
        let curpos = col('.')
        let curletter = curline[curpos-1]
        let prevletter = curline[curpos-2]
        if (prevletter == '"' && curletter == '"') ||
\          (prevletter == "'" && curletter == "'") ||
\          (prevletter == "(" && curletter == ")") ||
\          (prevletter == "{" && curletter == "}") ||
\          (prevletter == "[" && curletter == "]")
            if len(s:closeStack) > 0
                call remove(s:closeStack,0)
            endif
            return "\<Delete>\<BS>"
        else
            return "\<BS>"
        endif
    "endif
endf
endif

