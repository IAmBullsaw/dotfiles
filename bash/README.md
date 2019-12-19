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


## link.sh
This script can install/uninstall the scripts and the settings

| Command | Description |
| --- | --- |
| -i or -u | set script to install or uninstall |
| -b | .bash_aliases |
| -s | all scripts found in bash/scripts |
