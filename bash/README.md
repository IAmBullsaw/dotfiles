# bash

## The structure 

### .bashrc
This file loads other bash_* files and itself contains total environment variables

### .bash_aliases
These are the most common aliases I use for bash.

### .bash_functions
Here I define things that are too large to be an alias as funtions.

### .bash_prompt
This is my bash prompt definition, with helper functions related to it.


### .bash_constants
Here I define constans, which is super empty right now but had a purpose before. 
I have the alias `constants` which lists  all defined constants.


### .bash_work
In this file I have work related  stuff that will never be pushed to GitHub, which is why the file is only seen in .bashrc

## installation

Use soft links via `ln -s` to install them

```bash
sudo -- -sh -c "ln -s /home/$USER/dotfiles/bash/.bashrc /home/$USER/.bashrc;\
                ln -s /home/$USER/dotfiles/bash/.bash_aliases /home/$USER/.bash_aliases;\
                ln -s /home/$USER/dotfiles/bash/.bash_functions /home/$USER/.bash_functions;\
                ln -s /home/$USER/dotfiles/bash/.bash_prompt /home/$USER/.bash_prompt;\
                ln -s /home/$USER/dotfiles/bash/.bash_constants /home/$USER/.bash_constants;"
```

often it will help to throw on a `-f` in the mix.
