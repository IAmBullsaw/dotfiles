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

