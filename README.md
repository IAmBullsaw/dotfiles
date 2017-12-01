# dotfiles
These are my dotfiles; Information about each can be found in their part of this readme.

* [Bash](#bash_aliases)
* [Emacs](#initel)
* [Spacemacs](#spacemacs)
* [Visual Studio Code](#visual-studio-code)

# scripts
These scripts are meant to aid with installation of relevant dotfiles.
Options and examples are found by running the scripts with the "-h" flag. ( Or you know, read the bash scrpt ^^)

## link.sh
Links all dotfiles in the correct places.
Needs to be run from this folder(as in the cloned repository folder).

## update.sh
A smaller script meant to check if there's been any changes in the dotfiles git repo and if so, pull the latest from the git repository.

## .bash_aliases
These are the most common aliases I use for bash.

## init.el
[What is emacs?](https://www.gnu.org/software/emacs/)

Before switching to spacemacs this was my emacs config.

## .spacemacs
[What is spacemacs?](http://spacemacs.org/)

Theme:
* flatland (The default theme)
* sanityinc-solarized-dark
* sanityinc-solarized-light
* spacemacs-dark

Theme overrides:
* line numbers are red.

Settings:
* shell default pos: bottom
* shell default height: 30
* remove trailing whitespace on save
* Relative line numbers
* Maximize on startup
* finer undo (do not undo one whole insert)
* When in spacemacs buffer, clicking on latest file does not yank whatever into the newly opened buffer. (What a feature...)
* fly-check for g++ and clang is c++17

Keyboard bindings:
* C-ö C-ä makes curly braces {} respectively. (Very nice on nordic keyboard layout)

Layers added:
* ivy
* auto-completion
* emacs-lisp
* git
* markdown
* syntax-checking
* version-control
* c-c++
* themes-megapack

## Visual Studio Code
Files are within subdirectory /VScode

### keybindings.json
* C-ö C-ä makes curly braces {} respectively.

### settings.json
* Disable annoying neovim message
* Don't ignore extension recommendations
* Format on save
