" Vim syntax file
" Language:	BCM43xx firmware assembly
" Maintainer:	Michael Buesch <mb@bu3sch.de>
" Last Change:	2008 May 16

" Based on work by Kevin Dahlhausen <kdahlhaus@yahoo.com>

" For version 5.x: Clear all syntax items
" For version >=6.0: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn case ignore


syn match b43Type "\.text"
syn match b43Type "\.initvals\([a-z0-9_]+\)"

syn match b43Label		"[a-z_][a-z0-9_]*:"he=e-1
syn match b43Identifier		"[a-z_][a-z0-9_]*"

syn match decNumber		"0\+[1-7]\=[\t\n$,; ]"
syn match decNumber		"[1-9]\d*"
syn match hexNumber		"0[xX][0-9a-fA-F]\+"


syn region b43CommentC		start="/\*" end="\*/"
syn match b43CommentCpp		"//.*$"

syn match b43Include		"#include"
syn match b43Cond		"#if"
syn match b43Cond		"#ifdef"
syn match b43Cond		"#else"
syn match b43Cond		"#endif"
syn match b43Macro		"#define"
syn match b43Macro		"#undef"

syn match b43Directive		"%[a-zA-Z0-9_]+"


syn case match

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_b43_syntax_inits")
  if version < 508
    let did_b43_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  " The default methods for highlighting.  Can be overridden later
  HiLink b43Label	Label
  HiLink b43CommentC	Comment
  HiLink b43CommentCpp	Comment
  HiLink b43Directive	Statement

  HiLink b43Include	Include
  HiLink b43Cond	PreCondit
  HiLink b43Macro	Macro

  HiLink hexNumber	Number
  HiLink decNumber	Number

  HiLink b43Identifier Identifier
  HiLink b43Type	Type

  delcommand HiLink
endif

let b:current_syntax = "b43"
