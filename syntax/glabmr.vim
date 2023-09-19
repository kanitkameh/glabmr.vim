" Vim syntax file
" Language:	Merge Request Plugin
" Maintainer:	Kamen Vakavchiev <kanitkameh@gmail.com>
" Last Change:	2023 Aug 24
" Remark:	Used by my gitlab merge request plugin.

if exists("b:current_syntax")
  finish
endif

let b:current_syntax="glabmr"

syntax match mergerequestBranch /Target:/  
syntax match mergerequestBranch /Source:/  
syntax match mergerequestTitle /Title:/  
syntax match mergerequestTitle /Assignee:/  
syntax match mergerequestDescription /Description:/  


hi def link mergerequestDescription	Identifier
hi def link mergerequestTitle Identifier
hi def link mergerequestBranch Identifier
