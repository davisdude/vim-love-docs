" Vim plugin for LÖVE syntax highlighting and help file
" https://github.com/davisdude/vim-love-docs
" Last Change: 2017 July 2017
" Maintainer:  Davis Claiborne <davisclaib@gmail.com>
" License:     MIT

let s:save_cpo = &cpo

if exists( 'g:lovedocs_loaded' )
	finish
endif
let g:lovedocs_loaded = 1

" Allow custom colors for LOVE functions
if !exists( 'g:lovedocs_colors' )
	let g:lovedocs_colors = 'guifg=#ff60e2 ctermfg=206'
endif

" Reset compatibility
let &cpo = s:save_cpo
