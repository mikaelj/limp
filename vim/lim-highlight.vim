" 
" lim/vim/lim-highlight.vim
"
" URL:
" http://mikael.jansson.be/hacking
"
" Description:
" Highlight parens and containing s-exps
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
" 2008-04-25
" * Fixed regressions. Now properly highlights blocks again.
"
" 2008-04-18 
" * Removed all mappings
" * Removed < 7.00 compatibility
" * Renamed to Lim-Highlight
" * Changed from Search to Brackets[Block]
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
        "------------------------------------------
        " We are at a bracket character
        "------------------------------------------
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
	    let mtchline2 = line('.')
	    let mtchcol2 = col('.')
	    let mtchline1 = mtchline
	    let mtchcol1 = mtchcol

	    call s:PerformMatch(mtchline1, mtchcol1, mtchline2, mtchcol2)
        else
	    2match none
            match none
        endif

    " if g:HiMtchBrkt_surround exists and is true, then highlight the surrounding brackets
    "elseif exists("g:HiMtchBrkt_surround") && g:HiMtchBrkt_surround
    else
        "------------------------------------------
        " We are inside brackets!
        "------------------------------------------
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

	    call s:PerformMatch(mtchline1, mtchcol1, mtchline2, mtchcol2)
        else
            match none
            2match none
        endif
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

fun! s:PerformMatch(line1, col1, line2, col2)
    let line1 = a:line1
    let col1 = a:col1
    let line2 = a:line2
    let col2 = a:col2

    if line1 == line2
	" at a single line => sort points on columns
	if col1 > col2
	    let tmp = col2
	    let col2 = col1
	    let col1 = tmp
	    let tmp = line2
	    let line2 = line1
	    let line1 = tmp
	endif
	exe '2match BracketsBlock /\%'.line1.'l\%>'.col1.'v\%<'.col2.'v/'
    else
	" at a single line => sort points on lines
	if line1 > line2
	    let tmp = line2
	    let line2 = line1
	    let line1 = tmp
	    let tmp = col2
	    let col2 = col1
	    let col1 = tmp
	endif
	exe '2match BracketsBlock /\%'.line1.'l\%>'.col1.'v\|\%>'.line1.'l\%<'.line2.'l\|\%'.line2.'l\%<'.col2.'v/'
    endif

    exe 'match Brackets /\%'.line1.'l\%'.col1.'v\|\%'.line2.'l\%'.col2.'v/'
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

