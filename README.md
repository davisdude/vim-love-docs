Vim LOVE Docs
===

Installing
---

- Pathogen: Put in `vimfiles/bundles`
- Vundle: Should work (untested)
- Other: Put the folders (other than [src](src)) into their corresponding directories in `vimfiles`. 



The file included should work fine until the next update of LOVE.

The bat and sh files assume you have `love` mapped to the most recent version of LOVE or set in your environment path variable. If you're on Windows, add the directory path to LOVE to the `path` environment variable. If you're on Linux, you should know how to do that.

There is also a working portion that is not yet complete. This will allow you to type `help love-graphics-draw` (for example) to get the wiki entry from that. 
Currently implemented:
- Modules

To-Do:
- Enums
- Callbacks
- Make args and returns that are enums point to enums
- Generate tags file

Screenshots
---

![](src/pics/screen1.png)
![](src/pics/screen2.png)
