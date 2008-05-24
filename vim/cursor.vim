" 
" limp/vim/cursor.vim
"
" URL:
" http://mikael.jansson.be/hacking
"
" Description:
" Save/restore cursor position in window (mostly obsoleted by Vim7 though)
"
" Version:
" 0.2
"
" Date:
" 2008-04-25
"
" Authors:
" Mikael Jansson <mail@mikael.jansson.be>
" Charles E. Campbell, Jr.  <drNchipO@ScampbellPfamilyA.Mbiz>-NOSPAM
"
" Changelog:
" 2008-04-18 
" * Removed all leader mappings
"
" Usage:
"   call Cursor_push()
"   let cursor = Cursor_get()
"
"   call Cursor_pop()
"   call Cursor_set(cursor)
"

" Load Once: {{{1

let s:keepcpo        = &cpo
set cpo&vim

" -----------------------
"  Public Interface: {{{1
" -----------------------
let s:modifier= "sil keepj "


" assume that all of the file has been loaded & defined once
" if one of the functions are defined.
if exists("*Cursor_get")
    finish
endif

" Cursor_get: {{{1
" Return the current cursor (as an executable command!)
"
fun! Cursor_get()
    if line(".") == 1 && getline(1) == ""
        return ""
    endif

    " disable various scrolling trickery
    let so_keep   = &so
    let siso_keep = &siso
    let ss_keep   = &ss
    set so=0 siso=0 ss=0

    let swline = line(".")
    let swcol = col(".")
    let swwline = winline() - 1
    let swwcol = virtcol(".") - wincol()
    let cursordata = "call Window_goto_by_buffer_number(".winbufnr(0).")|silent ".swline
    let cursordata = cursordata."|".s:modifier."norm! 0z\<cr>"
    if swwline > 0
        let cursordata = cursordata.":".s:modifier."norm! ".swwline."\<c-y>\<cr>"
    endif
    if swwcol > 0
        let cursordata = cursordata.":".s:modifier."norm! 0".swwcol."zl\<cr>"
    endif
    let cursordata = cursordata.":".s:modifier."call cursor(".swline.",".swcol.")\<cr>"

    " restore scrolling flags
    let &so = so_keep
    let &siso = siso_keep
    let &ss = ss_keep

    return cursordata
endfun

" Cursor_set: {{{1
" Set the current cursor to an old one
"
fun! Cursor_set(cursordata)
    exe "silent ".a:cursordata
endfun


" ---------------------------------------------------------------------
" Cursor_push {{{1
"    let cursor = Cursor_push()   save window position in b:cursor_position_{b:cursor_position_index}
"                                 and return cursor.
fun! Cursor_push(...)
    let cursordata = Cursor_get()

    " save window position in
    " b:cursor_position_{b:cursor_position_index} (stack)
    if !exists("b:cursor_position_index")
        let b:cursor_position_index= 1
    else
        let b:cursor_position_index = b:cursor_position_index + 1
    endif

    let b:cursor_position_{b:cursor_position_index} = cursordata

    return cursordata
endfun

" ---------------------------------------------------------------------
" Cursor_pop: {{{1
fun! Cursor_pop()
  if line(".") == 1 && getline(1) == ""
   return ""
  endif
  let so_keep   = &so
  let siso_keep = &siso
  let ss_keep   = &ss
  set so=0 siso=0 ss=0

   " use saved window position in b:cursor_position_{b:cursor_position_index} if it exists
   if exists("b:cursor_position_index") && exists("b:cursor_position_{b:cursor_position_index}")
        try
         exe "silent! ".b:cursor_position_{b:cursor_position_index}
        catch /^Vim\%((\a\+)\)\=:E749/
         " ignore empty buffer error messages
        endtry
        " normally drop top-of-stack by one
        " but while new top-of-stack doesn't exist
        " drop top-of-stack index by one again
        if b:cursor_position_index >= 1
             unlet b:cursor_position_{b:cursor_position_index}
             let b:cursor_position_index= b:cursor_position_index - 1
             while b:cursor_position_index >= 1 && !exists("b:cursor_position_{b:cursor_position_index}")
                  let b:cursor_position_index= b:cursor_position_index - 1
             endwhile
             if b:cursor_position_index < 1
                  unlet b:cursor_position_index
             endif
        endif
   else
        echohl WarningMsg
        echomsg "***warning*** need to cursor_save() first!"
        echohl None
   endif

  " seems to be something odd: vertical motions after RWP
  " cause jump to first column.  Following fixes that
    if wincol() > 1
        silent norm! hl
    elseif virtcol(".") < virtcol("$")
        silent norm! lh
    endif

    let &so   = so_keep
    let &siso = siso_keep
    let &ss   = ss_keep
endfun

" ---------------------------------------------------------------------
" Window_goto_by_buffer_number: go to window holding given buffer (by number) {{{1
"   Prefers current window; if its buffer number doesn't match,
"   then will try from topleft to bottom right
fun! Window_goto_by_buffer_number(bufnum)
  if winbufnr(0) == a:bufnum
   return
  endif
  winc t
  let first=1
  while winbufnr(0) != a:bufnum && (first || winnr() != 1)
  	winc w
	let first= 0
   endwhile
endfun


" ---------------------------------------------------------------------
" ListWinPosn:
"fun! ListWinPosn()                                                        " Decho 
"  if !exists("b:cursor_position_index") || b:cursor_position_index == 0             " Decho 
"   call Decho("nothing on SWP stack")                                     " Decho
"  else                                                                    " Decho
"   let jwinposn= b:cursor_position_index                                       " Decho 
"   while jwinposn >= 1                                                    " Decho 
"    if exists("b:cursor_position{jwinposn}")                              " Decho 
"     call Decho("winposn{".jwinposn."}<".b:cursor_position{jwinposn}.">") " Decho 
"    else                                                                  " Decho 
"     call Decho("winposn{".jwinposn."} -- doesn't exist")                 " Decho 
"    endif                                                                 " Decho 
"    let jwinposn= jwinposn - 1                                            " Decho 
"   endwhile                                                               " Decho 
"  endif                                                                   " Decho
"endfun                                                                    " Decho 
"com! -nargs=0 LWP	call ListWinPosn()                                    " Decho 


" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo = s:keepcpo
unlet s:keepcpo

" ---------------------------------------------------------------------
"  Modelines: {{{1
" vim: ts=4 fdm=marker
