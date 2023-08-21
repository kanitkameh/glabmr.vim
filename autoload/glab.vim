" StartDiscussion: {{{
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
    let currentBranch = system("git branch --show-current")
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
