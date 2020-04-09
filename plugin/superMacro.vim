
nnoremap <silent> qs <CMD>call superMacro#superMacro()<CR>
nnoremap <silent> qc <CMD>call superMacro#superMacro()<CR>ciw
nnoremap <silent> qq <CMD>call superMacro#toggleMark(getpos('.')[1:2], -1)<CR>
nnoremap <silent> qd <CMD>call superMacro#eraseAllMarks(0)<CR>
nnoremap <silent> q/ <CMD>call superMacro#toggleSearchMark()<CR>
nnoremap <silent> qn <CMD>call superMacro#moveToNextMark(0)<CR>
nnoremap <silent> qp <CMD>call superMacro#moveToPrevMark()<CR>
vnoremap <silent> qq :<C-u>call superMacro#selectionToMarks()<CR>
vnoremap <silent> qs :<C-u>call superMacro#selectionToMarks()<CR>:<C-u>call superMacro#superMacro()<CR>
vnoremap <silent> I :<C-u>call superMacro#selectionToMarks()<CR><CMD>call superMacro#superMacroInsert()<CR>
" nnoremap <silent> <C-q> lb<CMD>call superMacro#toggleMark(getpos('.')[1:2], 1)<CR><CMD>call search('\<'.expand('<cword>').'\>')<CR><CMD>call superMacro#toggleMark(getpos('.')[1:2], 1)<CR>
nnoremap <silent> <C-q> <CMD>call superMacro#enterInteractiveMode()<CR>
