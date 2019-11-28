
if ! exists("g:superMacroMarks")
    let g:superMacroMarks = {}
endif

let g:superMacroOldMarksSaved = 0
let g:superMacroUsleMarks = "ertyuiopdfghjklcvbnm"

let g:superMacroUseMarks = 0

hi def MacroMark cterm=bold ctermbg=darkgray ctermfg=white

" To compare 2 positions, 
" * pos1 < pos2 => returns  1
" * pos1 = pos2 => returns  0
" * pos1 > pos2 => returns -1
function! s:comparePositions(pos1, pos2)
    if a:pos1[0] < a:pos2[0]
        return 1
    endif
    if a:pos1[0] > a:pos2[0]
        return -1
    endif
    if a:pos1[1] < a:pos2[1]
        return 1
    endif
    if a:pos1[1] > a:pos2[1]
        return -1
    endif
    return 0
endfunction

function! superMacro#findAvailableMark()
    let i=0
    let mark=''
    while i < len(g:superMacroUsableMarks) && mark == ''
        let found = 0
        for k in keys(g:superMacroMarks)
            if g:superMacroUsableMarks[i] == g:superMacroMarks[k]
                let found = 1
            endif
        endfor
        if found == 0
            let mark = g:superMacroUsableMarks[i]
        endif
        let i += 1
    endwhile

    return mark
endfunction

function! superMacro#getMarkPos(key)
    if ! has_key(g:superMacroMarks, a:key)
        return 0
    endif

    if g:superMacroUseMarks == 1
        return getpos("'".g:superMacroMarks[a:key])[1:2]
    else
        return g:superMacroMarks[a:key]
    endif
endfunction

function! superMacro#setMarkPos(pos)
    if g:superMacroUseMarks == 1

        let mark = superMacro#findAvailableMark()

        if mark == ''
            return
        endif

        call setpos("'" . mark, [0] + a:pos + [0])
        let id = matchadd('MacroMark', '\%''' . mark)
        call extend(g:superMacroMarks, {id : mark})

    else

        let id = matchadd('MacroMark', '\%' . a:pos[0] . 'l\%' . a:pos[1] . 'c')
        call extend(g:superMacroMarks, {id : a:pos})

    endif
endfunction

function! superMacro#delMarkPos(key)

    if g:superMacroUseMarks == 1
        exe 'delmarks ' . g:superMacroMarks[a:key]
    endif

    call matchdelete(a:key)
    call remove(g:superMacroMarks, a:key)

endfunction

" To turn on/off a mark
function! superMacro#toggleMark(pos)

    if reg_recording() != ''
        return
    endif

    if g:superMacroOldMarksSaved == 1
        call superMacro#eraseAllMarks(1)
    endif

    for k in keys(g:superMacroMarks)
        if superMacro#getMarkPos(k) == a:pos
            call superMacro#delMarkPos(k)
            return
        endif
    endfor

    call superMacro#setMarkPos(a:pos)

endfunction

" To toggle marks on the current search pattern
function! superMacro#toggleSearchMark()

    let g:curpos = getpos('.')

    call setpos('.', [0,1,1,0])

    while 1
        let pos = search(@/, 'W')
        if pos[0] == 0
            break
        endif
        call superMacro#toggleMark(getpos('.')[1:2])
    endwhile

    call setpos('.', g:curpos)

endfunction

" To delete all marks (keeps a save if not 'truely')
function! superMacro#eraseAllMarks(truely)

    for key in keys(g:superMacroMarks)
        call superMacro#delMarkPos(key)
    endfor

endfunction

" To move the cursor to the next mark
function! superMacro#moveToNextMark(inclusive)
    let minPos = []

    let curPos = getpos('.')[1:2]
    for key in keys(g:superMacroMarks)
        let pos = superMacro#getMarkPos(key)
        
        if a:inclusive > 0
            let test = s:comparePositions(curPos, pos) >= 0
        else
            let test = s:comparePositions(curPos, pos) > 0
        endif

        if test
            if len(minPos) == 0 || s:comparePositions(pos, minPos) > 0
                let minPos = pos
            endif
        endif
    endfor

    if len(minPos) > 0
        call setpos('.', [0] + minPos + [0] )
        return 1
    endif
    return 0
endfunction

" To move cursor to the previous mark
function! superMacro#moveToPrevMark()
    let maxPos = []

    let curPos = getpos('.')[1:2]
    for key in keys(g:superMacroMarks)
        let pos = superMacro#getMarkPos(key)
        
        if s:comparePositions(curPos, pos) < 0
            if len(maxPos) == 0 || s:comparePositions(pos, maxPos) < 0
                let maxPos = pos
            endif
        endif
    endfor

    if len(maxPos) > 0
        call setpos('.', [0] + maxPos + [0] )
        return 1
    endif
    return 0
endfunction

" To start the macro
function! superMacro#startsuperMacro()
    let s = superMacro#moveToNextMark(1)
    if s == 0
        let s = superMacro#moveToPrevMark()
    endif
    if s == 0
        return
    else
        call superMacro#toggleMark(getpos('.')[1:2])
    endif
    norm!qs
endfunction

" To end the macro and apply it to all marks
function! superMacro#stopsuperMacro(beg, end)
    norm!q
    
    let @s = substitute(@s, 'qs$', '', '')
    let @s = a:beg . @s . a:end

    for key in keys(g:superMacroMarks)
        call setpos('.', [0] + superMacro#getMarkPos(key) + [0])
        norm!@s
    endfor
    
    call superMacro#eraseAllMarks(0)

endfunction

" Takes care of starting or stopping macro
function! superMacro#superMacro()

    if reg_recording() == ''
        call superMacro#startsuperMacro()
    else
        call superMacro#stopsuperMacro('', '')
    endif

endfunction

function superMacro#selectionToMarks()
    let begPos = getpos("'<")[1:2]
    let endPos = getpos("'>")[1:2]
    
    if begPos[0] > endPos[0]
        let [ begPos[0], endPos[0] ] = [ endPos[0], begPos[0] ]
    endif
    if begPos[1] > endPos[1]
        let [ begPos[1], endPos[1] ] = [ endPos[1], begPos[1] ]
    endif

    let i = begPos[0]
    while i <= endPos[0]
        
        call superMacro#toggleMark( [ i, begPos[1] ] )
        let i += 1
    endwhile
endfunction

function superMacro#superMacroInsert()
    augroup SuperMacro
    autocmd InsertLeave * call superMacro#endSuperMacroInsert()
    augroup END

    call superMacro#superMacro()
    startinsert
endfunction

function superMacro#endSuperMacroInsert()
    autocmd! SuperMacro InsertLeave *
    
    let curPos = getpos('.')
    stopinsert
    call superMacro#stopsuperMacro('i', '')
    call setpos('.', curPos)
endfunction
