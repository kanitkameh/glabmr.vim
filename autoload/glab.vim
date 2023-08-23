
function! glab#StartDiscussion() abort
    echo "Starting gitlab discussion"
endfunction
" }}}

" Creates the buffer where you enter data for the merge request
function! glab#CreateMergeRequest(...) abort
    if a:0 > 0
        let targetBranch = a:1
    else
        " TODO search 
        let targetBranch = "main"
    endif

    new
    let currentBranch = systemlist("git branch --show-current")[0]
    let text = []
    let text += [ "Source: " .. currentBranch ]
    " most of time you want to merge your changes to main/master
    let text += [ "Target: " .. targetBranch ] 
    let text += [ "Title: " .. "Add title here"]
    let text += [ "Description: " .. "Add description here"]
    call append(0,text)
endfunction

function! glab#SubmitMergeRequest() abort
    let sourceBranchLine = getline(search('Source: '))
    let sourceBranch = matchstr(sourceBranchLine, 'Source: \zs.*.\ze$')
    let targetBranchLine = getline(search('Target: '))
    let targetBranch = matchstr(targetBranchLine, 'Target: \zs.*.\ze$')
    let titleLine = getline(search('Title: '))
    let title = matchstr(titleLine, 'Title: \zs.*.\ze$')
    let descriptionLine = getline(search('Description: '))
    let description = matchstr(descriptionLine, 'Description: \zs.*.\ze$')

    let mrCommand = 'glab mr create' ..
                \ ' -s ' .. shellescape(sourceBranch) .. 
                \ ' -b ' .. shellescape(targetBranch) ..
                \ ' -t ' .. shellescape(title) ..
                \ ' -d ' .. shellescape(description) ..
                \ ' --yes' | "Skip submission confirmation
    echomsg mrCommand
    echomsg system(mrCommand) 
    q!
endfunction

function! s:refreshMergeRequestList() abort
    call deletebufline(bufnr(),'1','$')
    %read!glab mr list
endfunction

function! glab#ListMergeRequests() abort
    new
    call s:refreshMergeRequestList()
    call append("$",["(a)pprove, (r)evoke, (c)lose, (m)erge, (d)iff, (v)iew, (n)ote"])
    nnoremap <buffer> <silent> a :call glab#ApproveMergeRequest()<CR>
    nnoremap <buffer> <silent> r :call glab#RevokeMergeRequest()<CR>
    nnoremap <buffer> <silent> c :call glab#CloseMergeRequest()<CR>
    nnoremap <buffer> <silent> m :call glab#MergeMergeRequest()<CR>
    nnoremap <buffer> <silent> d :call glab#MergeRequestDiff()<CR>
    nnoremap <buffer> <silent> v :call glab#MergeRequestView()<CR>
    nnoremap <buffer> <silent> n :call glab#NoteMergeRequest()<CR>
endfunction

function! s:getMergeRequest()
    let line = getline(".")
    let parsedLine = matchlist(line,'!\(\d*\).*(\(.*\)) ← (\(.*\))')
    let mrNumber = parsedLine[1]
    let destinationBranch = parsedLine[2]
    let sourceBranch = parsedLine[3]
    let mergeRequest = #{
                \ number: mrNumber,
                \ sourceBranch: sourceBranch,
                \ destinationBranch: destinationBranch 
                \ }
    return mergeRequest
endfunction

function! glab#ApproveMergeRequest() abort
    let mr = s:getMergeRequest()
    echomsg "Approving " .. mr.number .. " " mr.destinationBranch .. " ← " .. mr.sourceBranch
    echomsg system('glab mr approve ' .. mr.number)
    call s:refreshMergeRequestList()
endfunction

function! glab#RevokeMergeRequest() abort
    let mr = s:getMergeRequest()
    echomsg "Revoking " .. mr.number .. " " mr.destinationBranch .. " ← " .. mr.sourceBranch
    echomsg system('glab mr revoke ' .. mr.number)
    call s:refreshMergeRequestList()
endfunction

function! glab#CloseMergeRequest() abort
    let mr = s:getMergeRequest()
    echomsg "Closing " .. mr.number .. " " mr.destinationBranch .. " ← " .. mr.sourceBranch
    echomsg system('glab mr close ' .. mr.number)
    call s:refreshMergeRequestList()
endfunction

function! glab#MergeMergeRequest() abort
    let mr = s:getMergeRequest()
    echomsg "Merge " .. mr.number .. " " mr.destinationBranch .. " ← " .. mr.sourceBranch
    echomsg system('glab mr merge ' .. mr.number)
    call s:refreshMergeRequestList()
endfunction

function! glab#MergeRequestDiff() abort
    let mr = s:getMergeRequest()
    exe 'silent !git diff '.. mr.destinationBranch .. " " .. mr.sourceBranch
    redraw! " silent ! requires a redraw
endfunction

function! glab#NoteMergeRequest() abort
    let mr = s:getMergeRequest()
    function! s:NoteBufferOnQuit() abort closure
        echomsg mr
        let fileContent = getline('0','$')->join()->shellescape()
        echomsg system('glab mr note ' .. mr.number .. ' --message ' .. fileContent)
    endfunction

    echomsg "Note " .. mr.number .. " " mr.destinationBranch .. " ← " .. mr.sourceBranch
    new
    call setline('0','Enter comment here')
    command -buffer MergeRequestNote call s:NoteBufferOnQuit()
endfunction
function! glab#MergeRequestView() abort
    let mergeRequest = s:getMergeRequest()
    exe 'silent !glab mr view ' ..  mergeRequest.number
    redraw! " silent ! requires a redraw
endfunction
