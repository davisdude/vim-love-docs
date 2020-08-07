" Help extensions for vim-love-docs
" This is based on luarefvim

" Only apply syntax changes to our help docs (which will actually contain
" these prefixes).
if -1 == stridx(resolve(expand('%:p')), resolve(expand("<sfile>:p:h:h:h") .'/doc/'))
    finish
endif

syn clear helpHyperTextJump
" helpHyperTextJump copied from $VIMRUNTIME/ftplugin/help.vim
if has("ebcdic")
    syn match helpHyperTextJump	"\\\@<!|[^"*|]\+|" contains=helpBar,helpHideLrv,helpHideLove
else
    syn match helpHyperTextJump	"\\\@<!|[#-)!+-~]\+|" contains=helpBar,helpHideLrv,helpHideLove
endif

if has("conceal")
    syn match helpHideLrv		contained "\<lrv-" conceal
    syn match helpHideLove		contained "\<love-" conceal
else
    syn match helpHideLrv		contained "\<lrv-"
    syn match helpHideLove		contained "\<love-"
endif

hi def link helpHideLrv         Ignore
hi def link helpHideLove        Ignore
