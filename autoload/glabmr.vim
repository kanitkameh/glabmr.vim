function! s:completeGitBranches(findstart,base) abort
    if(a:findstart)
        let line = getline('.')
        let column = match(line,'Target: \zs.\ze')
        return column
    else
        let branchLines = systemlist("git branch")
        call map(branchLines, {_, val -> trim(val)})
        return filter(branchLines, {_, val -> match(val, a:base) != -1})
    endif
endfunction    

" Creates the buffer where you enter data for the merge request
function! glabmr#CreateMergeRequest(...) abort
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

    command -buffer MergeRequestSubmit call glabmr#SubmitMergeRequest()
    set completefunc=s:completeGitBranches
    set filetype=glabmr
endfunction

function! glabmr#SubmitMergeRequest() abort
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
    silent %read!glab mr list
    redraw!
    call append("$",["(a)pprove, (r)evoke, (c)lose, (m)erge, (d)iff, (gd)iff file name, (v)iew, (n)ote"])
endfunction

function! glabmr#ListMergeRequests() abort
    new
    call s:refreshMergeRequestList()
    nnoremap <buffer> <silent> a :call glabmr#ApproveMergeRequest()<CR>
    nnoremap <buffer> <silent> r :call glabmr#RevokeMergeRequest()<CR>
    nnoremap <buffer> <silent> c :call glabmr#CloseMergeRequest()<CR>
    nnoremap <buffer> <silent> m :call glabmr#MergeMergeRequest()<CR>
    nnoremap <buffer> <silent> d :call glabmr#MergeRequestDiff()<CR>
    nnoremap <buffer> <silent> gd :call glabmr#MergeRequestFileNameDiff()<CR>
    nnoremap <buffer> <silent> v :call glabmr#MergeRequestView()<CR>
    nnoremap <buffer> <silent> n :call glabmr#NoteMergeRequest()<CR>
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

function! glabmr#ApproveMergeRequest() abort
    let mr = s:getMergeRequest()
    echomsg "Approving " .. mr.number .. " " mr.destinationBranch .. " ← " .. mr.sourceBranch
    echomsg system('glab mr approve ' .. mr.number)
    call s:refreshMergeRequestList()
endfunction

function! glabmr#RevokeMergeRequest() abort
    let mr = s:getMergeRequest()
    echomsg "Revoking " .. mr.number .. " " mr.destinationBranch .. " ← " .. mr.sourceBranch
    echomsg system('glab mr revoke ' .. mr.number)
    call s:refreshMergeRequestList()
endfunction

function! glabmr#CloseMergeRequest() abort
    let mr = s:getMergeRequest()
    echomsg "Closing " .. mr.number .. " " mr.destinationBranch .. " ← " .. mr.sourceBranch
    echomsg system('glab mr close ' .. mr.number)
    call s:refreshMergeRequestList()
endfunction

function! glabmr#MergeMergeRequest() abort
    let mr = s:getMergeRequest()
    echomsg "Merge " .. mr.number .. " " mr.destinationBranch .. " ← " .. mr.sourceBranch
    echomsg system('glab mr merge ' .. mr.number)
    call s:refreshMergeRequestList()
endfunction

function! glabmr#MergeRequestDiff() abort
    let mr = s:getMergeRequest()
    exe 'silent !git diff '.. mr.destinationBranch .. " " .. mr.sourceBranch
    redraw! " silent ! requires a redraw
endfunction
 
function! glabmr#MergeRequestFileNameDiff() abort
    let mr = s:getMergeRequest()
    new
    set bufhidden=hide
    exe '%read!git diff '.. mr.destinationBranch .. " " .. mr.sourceBranch .. ' --name-status'
    redraw! " silent ! requires a redraw
endfunction

function! glabmr#NoteMergeRequest() abort
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
function! glabmr#MergeRequestView() abort
    let mergeRequest = s:getMergeRequest()
    exe 'silent !glab mr view ' ..  mergeRequest.number
    redraw! " silent ! requires a redraw
endfunction
