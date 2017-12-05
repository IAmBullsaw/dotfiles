# dotfiles :metal:
These are my dotfiles; Information about each can be found in their respective readme.

* [Bash](bash/README.md)
* [Emacs](emacs/README.md)
* [Spacemacs](spacemacs/README.md) :heart:
* [Visual Studio Code](VScode/README.md)

# scripts
Each folder has it's own install script called link.sh.
These scripts are meant to aid with installation of the dotfile.
Options and examples are found by running the scripts with the "-h" flag. ( Or you know, read the bash script ^^)
The scripts needs to be run from their respective folder.

Example:
```
     cd dotfiles/spacemacs
     ./link.sh -i
```

There's a main script *under construction* called dotfiles.sh which is meant to be a wrapper for the smaller link.sh scripts.

There exists helper scripts that are supposed to be small and help the main script. These are found in /helpers
