function! s:completeGitBranches(findstart,base) abort
    if(a:findstart)
        let line = getline('.')
        let column = match(line, '^\(Target\|Source\): \zs')
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
        " TODO get default branch from glab? 
        let targetBranch = "main"
    endif

    tabnew
    let currentBranch = systemlist("git branch --show-current")[0]
    let text = []
    let text += [ "Source: " .. currentBranch ]
    " most of time you want to merge your changes to main/master
    let text += [ "Target: " .. targetBranch ] 
    let text += [ "Title: " .. "Add title here"]
    " Getting the first username
    let text += [ "Assignee: " .. s:getLoggedUsernames()[0]]
    "Description should always be last because the
    "glabmr#SubmitMergeRequest parses it until the end of buffer
    let text += [ "Description:" ]
    let text += [ "Add (multi-line) description starting from here" ]
    call append(0,text)

    command -buffer MergeRequestSubmit call glabmr#SubmitMergeRequest()
    set completefunc=s:completeGitBranches
    set filetype=glabmr
endfunction

function! s:getSingleLineMergeRequestAttribute(attribute) abort
    let attributeLine = getline(search(a:attribute .. ': '))
    let attributeValue = matchstr(attributeLine, a:attribute .. ': \zs.*.\ze$')
    return attributeValue
endfunction

function! s:getMultiLineMergeRequestAttribute(attribute) abort
    let attributeLines = getline(search(a:attribute .. ':') + 1, '$')
    let attributeValue = attributeLines->join("\n") 
    return attributeValue
endfunction

function! glabmr#SubmitMergeRequest() abort
    let sourceBranch = s:getSingleLineMergeRequestAttribute('Source')
    let targetBranch = s:getSingleLineMergeRequestAttribute('Target')
    let title = s:getSingleLineMergeRequestAttribute('Title')
    let assignee = s:getSingleLineMergeRequestAttribute('Assignee')
    let description = s:getMultiLineMergeRequestAttribute('Description')

    let mrCommand = 'glab mr create' ..
                \ ' -s ' .. shellescape(sourceBranch) .. 
                \ ' -b ' .. shellescape(targetBranch) ..
                \ ' -t ' .. shellescape(title) ..
                \ ' -a ' .. shellescape(assignee) ..
                \ ' -d ' .. shellescape(description) ..
                \ ' --remove-source-branch' ..
                \ ' --squash-before-merge' ..
                \ ' --yes' "Skip submission confirmation

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
    " TODO this may need configuration code changes if 'origin' isn't the gitlab remote
    let destinationBranch = 'origin/' .. parsedLine[2]
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
    !git fetch
    exe 'silent !git diff '.. mr.destinationBranch .. " " .. mr.sourceBranch
    redraw! " silent ! requires a redraw
endfunction
 
function! glabmr#MergeRequestFileNameDiff() abort
    let mr = s:getMergeRequest()
    new
    set bufhidden=hide
    !git fetch
    exe '%read!git diff '.. mr.destinationBranch .. "..." .. mr.sourceBranch .. ' --name-status'
    call append(0, "gf, <c-w>f and <c-w>gf open the files in git diff split")
    redraw! " silent ! requires a redraw
    
    let destinationAndSourceBranches = mr.destinationBranch .. '...' .. mr.sourceBranch .. ':%<CR>'
    let focusOnSourceWindow = '<C-w>l'
    execute 'nnoremap <buffer> gf gf:Gvdiffsplit ' .. destinationAndSourceBranches .. '<CR>' .. focusOnSourceWindow
    execute 'nnoremap <buffer> <c-w>f <c-w>f:Gvdiffsplit ' .. destinationAndSourceBranches .. '<CR>' .. focusOnSourceWindow
    execute 'nnoremap <buffer> <c-w>gf <c-w>gf:Gvdiffsplit ' .. destinationAndSourceBranches .. '<CR>' .. focusOnSourceWindow
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
    new
    exe 'silent %read!glab mr view ' ..  mergeRequest.number
    redraw! " silent ! requires a redraw
endfunction

function! s:getLoggedUsernames()
    "the logged user info is outputted on stdout this forwarding it to stdin
    let loggedLines = systemlist("glab auth status 2>&1 \| grep Logged") 
    let usernames = loggedLines->map({idx, line -> matchstr(line, 'as \zs.*.\ze (')})
    return usernames
endfunction
