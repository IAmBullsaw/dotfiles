###########
# Functions
###########

# Prints a list of the most frequently used commands.
# It's a good idea to make aliases for these
function most-frequent() {
         history | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl |  head -n10
}

function add-alias() {
         NAME=$1
         shift
         COMMAND="$@"

         echo -e "\nalias $NAME='$COMMAND'" >> ~/.bash_aliases && source ~/.bash_aliases
}

function relink-scripts() {
         TMPDIR=`pwd`
         cd ~/Scripts
         SCRIPTSDESTINATION=~/bin

         for FILE in *; do
             if [ ! -e "$SCRIPTDESTINATION/${FILE%%.*}" ]; then
                ln -s "`pwd`/$FILE" "$SCRIPTDESTINATION/${FILE%%.*}"
             fi
         done

         cd $TMPDIR
}

function update_current_branch() {
         CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
}

# gc -git commit
# simple function which wont allow me to commit to master branch
# it's part of my work flow, no questions asked
function gc() {
         CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
         if [ "$CURRENT_BRANCH" = "master" ]; then
                 echo "I won't allow you to commit directly to master branch"
                 echo "git go -b <insert branch name here>"
                 (exit 1)
         else
                 git commit "$@"
         fi
}

# Function which opens the Scripts/logbook associated with the current repo
# the logbook path is set relative to the repo root, one up 
# llb stands for local logbook
function llb() {
  if ! [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == "true" ]]; then
    echo "Error: This command must be run from within a Git repository."
  else
    ABSOLUTE_PATH="$(git rev-parse --show-toplevel)_logbook.md"
    logbook -t $ABSOLUTE_PATH $@
  fi
}


# this function simply compiles and opens the PlantUML file in eog
# if -r is provided, it removes the PNG file after viewing
function puml() {
    local remove_flag=false
    local input_file=""
    
    # Check if enough arguments are provided
    if [ $# -lt 1 ]; then
        echo "Error: Missing input file."
        echo "Usage: puml [OPTIONS] <filename.puml>"
        echo "Options:"
        echo "  -r, --remove    Remove PNG file after viewing"
        return 1
    fi
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -r|--remove)
                remove_flag=true
                shift
                ;;
            -*)
                echo "Error: Unknown option $1"
                echo "Usage: puml [OPTIONS] <filename.puml>"
                echo "Options:"
                echo "  -r, --remove    Remove PNG file after viewing"
                return 1
                ;;
            *)
                if [ -n "$input_file" ]; then
                    echo "Error: Too many input files. Only one file is allowed."
                    echo "Usage: puml [OPTIONS] <filename.puml>"
                    return 1
                fi
                input_file="$1"
                shift
                ;;
        esac
    done
    
    # Check if input file is provided
    if [ -z "$input_file" ]; then
        echo "Error: Missing input file."
        echo "Usage: puml [OPTIONS] <filename.puml>"
        return 1
    fi
    
    # Check if file exists
    if [ ! -f "$input_file" ]; then
        echo "Error: File '$input_file' does not exist."
        return 1
    fi
    
    # Check if file is a PlantUML file (by extension)
    if [[ ! "$input_file" == *.puml && ! "$input_file" == *.plantuml ]]; then
        echo "Warning: File '$input_file' doesn't have a standard PlantUML extension (.puml or .plantuml)."
        read -p "Do you want to continue? (y/n): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Get the output PNG filename (same name but with .png extension)
    local output_file="${input_file%.*}.png"
    
    echo "Compiling PlantUML file: $input_file"
    
    # Compile the PlantUML file
    plantuml "$input_file"
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to compile PlantUML file."
        return 1
    fi
    
    # Check if output file was created
    if [ ! -f "$output_file" ]; then
        echo "Error: Output file '$output_file' was not created."
        return 1
    fi
    
    echo "Displaying: $output_file"
    
    # Display the PNG file with EOG
    eog "$output_file"
    
    # Remove the PNG file if requested
    if [ "$remove_flag" = true ]; then
        echo "Removing: $output_file"
        rm "$output_file"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to remove file '$output_file'."
            return 1
        fi
    fi
    
    return 0
}
