if exists('g:loaded_glab') || &cp
    finish
endif
let g:loaded_glab = 0.1
let s:keepcpo = &cpo
set cpo&vim

command -nargs=? -complete=custom,s:gitBranches CreateMergeRequest call glab#CreateMergeRequest(<f-args>)

command SubmitMergeRequest call glab#SubmitMergeRequest()

" TODO other plugins have it
command StartDiscussion call glab#StartDiscussion()

" Arguments aren't used
function s:gitBranches(A,L,P)
    return system("git branch")
endfunction    

let &cpo = s:keepcpo
unlet s:keepcpo
