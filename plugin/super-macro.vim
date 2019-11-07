
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

function! s:findAvailableMark()
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

function! s:getMarkPos(key)
    if ! has_key(g:superMacroMarks, a:key)
        return 0
    endif

    if g:superMacroUseMarks == 1
        return getpos("'".g:superMacroMarks[a:key])[1:2]
    else
        return g:superMacroMarks[a:key]
    endif
endfunction

function! s:setMarkPos(pos)
    if g:superMacroUseMarks == 1

        let mark = s:findAvailableMark()

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

function! s:delMarkPos(key)

    if g:superMacroUseMarks == 1
        exe 'delmarks ' . g:superMacroMarks[a:key]
    endif

    call matchdelete(a:key)
    call remove(g:superMacroMarks, a:key)

endfunction

" To turn on/off a mark
function! s:toggleMark(pos)

    if reg_recording() != ''
        return
    endif

    if g:superMacroOldMarksSaved == 1
        call s:eraseAllMarks(1)
    endif

    for k in keys(g:superMacroMarks)
        if s:getMarkPos(k) == a:pos
            call s:delMarkPos(k)
            return
        endif
    endfor

    call s:setMarkPos(a:pos)

endfunction

" To toggle marks on the current search pattern
function! s:toggleSearchMark()

    let g:curpos = getpos('.')

    call setpos('.', [0,1,1,0])

    while 1
        let pos = search(@/, 'W')
        if pos[0] == 0
            break
        endif
        call s:toggleMark(getpos('.')[1:2])
    endwhile

    call setpos('.', g:curpos)

endfunction

" To delete all marks (keeps a save if not 'truely')
function! s:eraseAllMarks(truely)

    for key in keys(g:superMacroMarks)
        call s:delMarkPos(key)
    endfor

endfunction

" To move the cursor to the next mark
function! s:moveToNextMark(inclusive)
    let minPos = []

    let curPos = getpos('.')[1:2]
    for key in keys(g:superMacroMarks)
        let pos = s:getMarkPos(key)
        
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
function! s:moveToPrevMark()
    let maxPos = []

    let curPos = getpos('.')[1:2]
    for key in keys(g:superMacroMarks)
        let pos = s:getMarkPos(key)
        
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
function! s:startSuperMacro()
    let s = s:moveToNextMark(1)
    if s == 0
        let s = s:moveToPrevMark()
    endif
    if s == 0
        return
    else
        call s:toggleMark(getpos('.')[1:2])
    endif
    norm!qs
endfunction

" To end the macro and apply it to all marks
function! s:stopSuperMacro()
    norm!q
    
    let @s = substitute(@s, 'qs$', '', '')

    for key in keys(g:superMacroMarks)
        call setpos('.', [0] + s:getMarkPos(key) + [0])
        norm!@s
    endfor
    
    call s:eraseAllMarks(0)

endfunction

" Takes care of starting or stopping macro
function! s:superMacro()

    if reg_recording() == ''
        call s:startSuperMacro()
    else
        call s:stopSuperMacro()
    endif

endfunction

function s:selectionToMarks()
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
        
        call s:toggleMark( [ i, begPos[1] ] )
        let i += 1
    endwhile
endfunction

nnoremap <silent> qs :<C-u>call <SID>superMacro()<CR>
nnoremap <silent> qc :<C-u>call <SID>superMacro()<CR>ciw
nnoremap <silent> qq :<C-u>call <SID>toggleMark(getpos('.')[1:2])<CR>
nnoremap <silent> qd :<C-u>call <SID>eraseAllMarks(0)<CR>
nnoremap <silent> q/ :<C-u>call <SID>toggleSearchMark()<CR>
nnoremap <silent> qn :<C-u>call <SID>moveToNextMark(0)<CR>
nnoremap <silent> qp :<C-u>call <SID>moveToPrevMark()<CR>
vnoremap <silent> qq :<C-u>call <SID>selectionToMarks()<CR>
