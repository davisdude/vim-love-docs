" Vim plugin for running LOVE
" https://github.com/davisdude/vim-love-docs
" Last Change:	2017 March 29
" Maintainer:	Davis Claiborne <davisclaib@gmail.com>
" License:		This file is placed under public domain.

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
