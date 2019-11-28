
nnoremap <silent> qs :<C-u>call superMacro#superMacro()<CR>
nnoremap <silent> qc :<C-u>call superMacro#superMacro()<CR>ciw
nnoremap <silent> qq :<C-u>call superMacro#toggleMark(getpos('.')[1:2])<CR>
nnoremap <silent> qd :<C-u>call superMacro#eraseAllMarks(0)<CR>
nnoremap <silent> q/ :<C-u>call superMacro#toggleSearchMark()<CR>
nnoremap <silent> qn :<C-u>call superMacro#moveToNextMark(0)<CR>
nnoremap <silent> qp :<C-u>call superMacro#moveToPrevMark()<CR>
vnoremap <silent> qq :<C-u>call superMacro#selectionToMarks()<CR>
vnoremap <silent> qs :<C-u>call superMacro#selectionToMarks()<CR>:<C-u>call superMacro#superMacro()<CR>
vnoremap I :<C-u>call superMacro#selectionToMarks()<CR>:<C-u>call superMacro#superMacroInsert()<CR>
