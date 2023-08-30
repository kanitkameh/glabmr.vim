if exists('g:loaded_glabmr') || &cp
    finish
endif
let g:loaded_glabmr = 0.1
let s:keepcpo = &cpo
set cpo&vim

command -nargs=? -complete=customlist,s:gitBranches MergeRequestCreate call glabmr#CreateMergeRequest(<f-args>)

command MergeRequestList call glabmr#ListMergeRequests()

" Arguments aren't used
function s:gitBranches(A,L,P)
    let branchLines = systemlist("git branch")              
    call map(branchLines, {_, val -> trim(substitute(val, "^*", "", ""))})
    return branchLines
endfunction    

let &cpo = s:keepcpo
unlet s:keepcpo
