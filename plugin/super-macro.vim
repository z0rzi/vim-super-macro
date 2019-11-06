
if ! exists("g:superMacroMarks")
    let g:superMacroMarks = {}
endif

let g:superMacroOldMarksSaved = 0

let g:superMacroUsedMarks = "ertyuiopdfghjklcvbnm"

hi def MacroMark cterm=bold ctermbg=darkgray ctermfg=white

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

function! s:switchMark(pos)

    if reg_recording() != ''
        return
    endif

    if g:superMacroOldMarksSaved == 1
        call s:eraseAllMarks(1)
    endif

    for k in keys(g:superMacroMarks)
        if getpos("'".g:superMacroMarks[k])[1:2] == a:pos
            exe 'delmarks ' . g:superMacroMarks[k]
            call matchdelete(k)
            call remove(g:superMacroMarks, k)
            return
        endif
    endfor

    let i=0
    let mark=''
    while i < len(g:superMacroUsedMarks)
        if getpos("'" . g:superMacroUsedMarks[i])[1] == 0
            let mark = g:superMacroUsedMarks[i]
            break
        endif
        let i += 1
    endwhile

    if mark == ''
        return
    endif

    call setpos("'" . mark, [0] + a:pos + [0])
    let id = matchadd('MacroMark', '\%''' . mark)
    call extend(g:superMacroMarks, {id : mark})
endfunction

function! s:switchSearchMark()

    let g:curpos = getpos('.')

    call setpos('.', [0,1,1,0])

    while 1
        let pos = search(@/, 'W')
        if pos[0] == 0
            break
        endif
        call s:switchMark(getpos('.')[1:2])
    endwhile

    call setpos('.', g:curpos)

endfunction

function! s:restoreOldMarks()
    if g:superMacroOldMarksSaved == 0
        return
    endif

    for key in keys(g:superMacroMarks)
        let id = matchadd('MacroMark', '\%''' . g:superMacroMarks[key])
        call extend(g:superMacroMarks, {id : g:superMacroMarks[key]})
        call remove(g:superMacroMarks, key)
    endfor
endfunction

function! s:eraseAllMarks(truely)
    if a:truely == 0 && g:superMacroOldMarksSaved == 1
        call s:restoreOldMarks()
        let g:superMacroOldMarksSaved = 0
        return
    endif

    for key in keys(g:superMacroMarks)
        silent!call matchdelete(key)
    endfor

    if a:truely == 1
        let g:superMacroMarks = {}
        exe 'delmarks ' . g:superMacroUsedMarks
        let g:superMacroOldMarksSaved = 0
    else
        let g:superMacroOldMarksSaved = 1
    endif
endfunction

function! s:moveToNextMark(inclusive)
    let minPos = []

    let curPos = getpos('.')[1:2]
    for key in keys(g:superMacroMarks)
        let pos = getpos("'".g:superMacroMarks[key])[1:2]
        
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

function! s:moveToPrevMark()
    let maxPos = []

    let curPos = getpos('.')[1:2]
    for key in keys(g:superMacroMarks)
        let pos = getpos("'".g:superMacroMarks[key])[1:2]
        
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

function! s:startSuperMacro()
    let s = s:moveToNextMark(1)
    if s == 0
        let s = s:moveToPrevMark()
    endif
    if s == 0
        return
    else
        call s:switchMark(getpos('.')[1:2])
    endif
    norm!qs
endfunction

function! s:stopSuperMacro()
    norm!q
    
    let @s = substitute(@s, 'qs$', '', '')

    for key in keys(g:superMacroMarks)
        call setpos('.', getpos("'".g:superMacroMarks[key]))
        norm!@s
    endfor
    
    call s:eraseAllMarks(0)

endfunction

function! s:superMacro()

    if reg_recording() == ''
        call s:startSuperMacro()
    else
        call s:stopSuperMacro()
    endif

endfunction

nnoremap <silent> qs :call <SID>superMacro()<CR>
nnoremap <silent> qc :call <SID>superMacro()<CR>ciw
nnoremap <silent> qq :call <SID>switchMark(getpos('.')[1:2])<CR>
nnoremap <silent> qd :call <SID>eraseAllMarks(0)<CR>
nnoremap <silent> q/ :call <SID>switchSearchMark()<CR>
nnoremap <silent> qn :call <SID>moveToNextMark(0)<CR>
nnoremap <silent> qp :call <SID>moveToPrevMark()<CR>
