# dotfiles
These are my dotfiles. Well, more like dotfile.

## link.sh
A small script that links all dotfiles in the correct places.
Needs to be run from this folder(as in the cloned repository folder).

## update.sh
A smaller script meant to check if there's been any changes in the dotfiles and if so, pull the latest from the git repository.

# the dotfiles:
* [Bash](#.bash_aliases)
* [Emacs](#init.el)
* [Spacemacs](#.spacemacs)
* [Visual Studio Code](#Visual Studio Code)

# .bash_aliases
These are the most common aliases I use for bash.

# init.el
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
