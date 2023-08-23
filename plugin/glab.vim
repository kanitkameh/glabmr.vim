if exists('g:loaded_glab') || &cp
    finish
endif
let g:loaded_glab = 0.1
let s:keepcpo = &cpo
set cpo&vim

command -nargs=? -complete=custom,s:gitBranches MergeRequestCreate call glab#CreateMergeRequest(<f-args>)

command MergeRequestList call glab#ListMergeRequests()

" Arguments aren't used
function s:gitBranches(A,L,P)
    let branchLines = systemlist("git branch")
    call map(branchLines, {_, val -> trim(val)})
    return branchLines->join("\n")
endfunction    

let &cpo = s:keepcpo
unlet s:keepcpo
