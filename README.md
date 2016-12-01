Vim LOVE Docs
===

Vim syntax highlighting and helpfile for [LÖVE](http://love2d.org).

Usage
---

__Instalation:__

- Pathogen: Put in `vimfiles/bundles`
- Vundle: Should work (untested)
- Other: Put the folders (other than [src](src)) into their corresponding directories in `vimfiles`.

__Help files:__

The help files follow the pattern `love-NAME`. For instance:

Functions:
- `love-love.graphics.newImage`
- `love-love.window.setMode-flags`
- `love-love.window.setMode-flags-fullscreen`

Types and Sub-functions:
- `love-File`
- `love-File:isEOF`

Enums:
- `love-BufferMode`
- `love-BufferMode-constants`
- `love-BufferMode-full`

For sub-sections, they are hyphenated, such as `love-audio-functions`, `love-audio`, `love-audio-types`.

__Plugin:__

In your `vimrc` you can set the variable `g:lovedocs_colors` to any valid color (see `help highlight-args`). Defaults to `'guifg=#ff60e2 ctermfg=206'`.

The file included should work fine until the next update of LÖVE.

Running
---

In order to generate the files, navigate to the [src](src) directory to choose either the .bat or .sh file to do everything, then go to the main directory and copy the output folders to their corresponding folders:

- `git`: Mapped to Git client.
- `love`: Mapped to the LÖVE executable.
- `vim`: Mapped to `vim.exe` (or `gvim.exe`).

The current version was generated from [latest commit](https://github.com/love2d-community/love-api/commit/9f864c49818fc1d539184f922c9b6a6002ac55c1) from [love-api](https://github.com/love2d-community/love-api).

Screenshots
---

Plugins:
- [gruvbox](https://github.com/morhetz/gruvbox)
- [Rainbow](https://github.com/luochen1990/rainbow)
- [vim-love-docs](https://github.com/davisdude/vim-love-docs)

![](src/pics/screen1.png)
![](src/pics/screen2.png)
![](src/pics/screen3.png)
