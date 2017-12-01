#/bin/bash
git remote update
RESULT=`git status -uno | grep -c behind`
if [ $RESULT -eq 1 ]; then
    echo "Behind git. Updating..."
    git pull
    echo "You might want to re-link."
fi
