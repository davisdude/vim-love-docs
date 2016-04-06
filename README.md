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

Types:
- `love-File` or `love-filesystem-File`
- `love-File:isEOF`

Enums:
- `love-BufferMode` or `love-filesystem-BufferMode`
- `love-BufferMode-constants`
- `love-BufferMode-full`

For sub-sections, they are hyphenated, such as `love-audio-functions`, `love-audio`, `love-audio-types`.

__Plugin:__

In your `vimrc` you can set the variable `g:lovedocs_colors` to any valid color (see `help highlight-args`). Defaults to `'guifg=#ff60e2 ctermfg=206'`.

The file included should work fine until the next update of LÖVE.

Running
---

In order to generate the files, navigate to the [src](src) directory to choose which form to generate and run the `.bat` or `.sh` file depending on the machine you're using. These assume you have the following:

- `git`: Mapped to Git client.
- `love`: Mapped to the LÖVE executable.
- `vim`: Mapped to `vim.exe` (or `gvim.exe`).

The current version was generated from [latest commit](https://github.com/love2d-community/love-api/commit/8c640d693cc63151b15b177171ee4d0c9143d09a) from https://github.com/love2d-community/love-api.

Screenshots
---

Plugins:
- [gruvbox](https://github.com/morhetz/gruvbox)
- [Rainbow](https://github.com/luochen1990/rainbow)
- [vim-love-docs](https://github.com/davisdude/vim-love-docs)

![](src/pics/screen1.png)
![](src/pics/screen2.png)
![](src/pics/screen3.png)
