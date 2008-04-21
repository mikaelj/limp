"  Name:        Lim-Highlight <lim-highlight.vim>
"  Description: Highlight parens and containing s-exps
"  Authors:     Mikael Jansson <mail@mikael.jansson>
"               Charles E. Campbell, Jr.  <drNchipO@ScampbellPfamilyA.Mbiz>-NOSPAM
"  Version:     2008-04-20-lim
"  URL:         http://mikael.jansson.be/hacking
"  Requires:    Vim >= 700 
"  History:  {{{1
"    
"    2008-04-18 
"    * Removed all mappings
"    * Removed < 7.00 compatibility
"    * Renamed to Lim-Highlight
"
" Usage: {{{1
"   Before loading: 
"       let g:LimHighlight = 1
"   or after loading:
"       call LimHighlight_start()
"
" ---------------------------------------------------------------------
" Load Once: {{{1
if &cp || exists("g:loaded_lim_highlight")
    finish
endif
let g:loaded_lim_highlight = "2008-04-20-lim"
let s:keepcpo = &cpo
set cpo&vim

" disable matchparen: we do that ourselves.
let g:loaded_matchparen = 1

fun! LimHighlight_start()
    if exists("g:lim_highlight_active")
        return
    endif
    let g:lim_highlight_active = 1

    if !exists("*Cursor_get")
        " due to loading order, <plugin/lim-cursor.vim> may not have loaded yet.
        " attempt to force a load now.  Ditto for matchit!
        silent! runtime plugin/lim-cursor.vim
    endif
    silent! runtime plugin/matchit.vim

    " set whichwrap
    let s:wwkeep = &ww
    set ww=b,s,<,>,[,]

    augroup LimHighlight
        au!
        au CursorMoved * silent call s:LimHighlight_handler()
    augroup END

    set lz
    call s:LimHighlight_handler()
    set nolz
endfun

fun! LimHighlight_stop()
    set lz
    unlet g:lim_highlight_active
    match none
    2match none
 
    " remove cursorhold event for highlighting matching bracket
    augroup LimHighlight
        au!
    augroup END
 
    let &ww = s:wwkeep
    set nolz
endfun


" ---------------------------------------------------------------------
" LimHighlight_handler: this routine actually performs the highlighting of {{{1
" the matching bracket.
fun! <SID>LimHighlight_handler()
    if mode() =~ '['."\<c-v>".'vV]'
        " don't try to highlight matching/surrounding brackets while in
        " visual-block mode
        return
    endif

    " save
    let magickeep        = &magic
    let regdq            = @"
    let regunnamed       = @@
    let sokeep           = &so
    let sskeep           = &ss
    let sisokeep         = &siso
    let solkeep          = &sol
    let t_vbkeep         = &t_vb
    let vbkeep           = &vb
    silent! let regpaste = @*

    " turn beep/visual flash off
    set nosol vb t_vb= so=0 siso=0 ss=0 magic

    " remove every other character from the mps option set
    let mps = substitute(&mps,'\(.\).','\1','g')

    " grab a copy of the character under the cursor into @0
    silent! norm! yl

    " if the character grabbed in @0 is in the mps option set, then highlight
    " the matching character
    if stridx(mps,@0) != -1
        let curchr     = @0
        " determine match line, column.
        " Restrict search to currently visible portion of window.
        if &mps =~ curchr.':'
            let stopline           = line("w$")
            let chrmatch           = substitute(&mps,'^.*'.curchr.':\(.\).*$','\1','')
            let [mtchline,mtchcol] = searchpairpos(escape(curchr,'[]'),'',escape(chrmatch,'[]'),'n','',stopline)
        else
            let stopline           = line("w0")
            let chrmatch           = substitute(&mps,'^.*\(.\):'.curchr.'.*$','\1','')
            let [mtchline,mtchcol] = searchpairpos(escape(chrmatch,'[]'),'',escape(curchr,'[]'),'bn','',stopline)
        endif

        if mtchline != 0 && mtchcol != 0
            exe 'match Brackets /\%'.mtchline.'l\%'.mtchcol.'c/'
        else
            match none
            2match none
        endif

    " if g:HiMtchBrkt_surround exists and is true, then highlight the surrounding brackets
    "elseif exists("g:HiMtchBrkt_surround") && g:HiMtchBrkt_surround
    else
        let swp        = Cursor_get()
        let openers    = '['.escape(substitute(&mps,':.,\=',"","g"),']').']'
        let closers    = '['.escape(substitute(&mps,',\=.:',"","g"),']').']'
        call searchpair(openers,"",closers,'','',line("w$"))
        silent! norm! yl
        if stridx(mps,@0) != -1
            let mtchline1 = line('.')
            let mtchcol1  = virtcol('.')
            keepj norm! %
            let mtchline2 = line('.')
            let mtchcol2  = virtcol('.')
            call Cursor_set(swp)

            exe 'match Brackets /\%'.mtchline1.'l\%'.mtchcol1.'v\|\%'.mtchline2.'l\%'.mtchcol2.'v/'

            " mail@mikael.jansson.be
            " highlight the block within the parens.
            if mtchline2 == mtchline1
                if mtchcol1 > mtchcol2
                    let tmp = mtchcol1
                    let mtchcol1 = mtchcol2
                    let mtchcol2 = tmp
                endif
                exe '2match BracketsBlock /\%'.mtchline2.'l\%>'.mtchcol1.'v\%<'.mtchcol2.'v/'
            else
                exe '2match BracketsBlock /\%'.mtchline2.'l\%>'.mtchcol2.'v\|\%>'.mtchline2.'l\%<'.mtchline1.'l\|\%'.mtchline1.'l\%<'.mtchcol1.'v/'
            endif
        else
            match none
            2match none
        endif
    "else
    "    match none
    "    2match none
    endif
 
    " restore
    let &magic     = magickeep
    let @"         = regdq
    let @@         = regunnamed
    let &sol       = solkeep
    let &so        = sokeep
    let &siso      = sisokeep
    let &ss        = sskeep
    let &t_vb      = t_vbkeep
    let &vb        = vbkeep
    silent! let @* = regpaste
endfun


"
" disable paren colors (for Lisp rainbow)
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

" ---------------------------------------------------------------------
"  Auto Startup With LimHighlight: {{{1
if exists("g:LimHighlight") && g:LimHighlight == 1
    call LimHighlight_start()
endif

let &cpo = s:keepcpo
unlet s:keepcpo

