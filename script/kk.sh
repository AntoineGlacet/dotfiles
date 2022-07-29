#!/bin/bash

code="/mnt/c/Users/J00638/AppData/Local/Programs/Microsoft VS Code/bin/code"

########## Script
usage () {
    echo "====== cool function ====="
    echo "chown to current user => edit in vscode => restore file to root after"
    echo "Usage : kk FILE"
    echo "====== cool function ====="
}

if [[ $# != 0 ]]; then
    FILE=$1
    if [[ -f "$FILE" ]]; then
        owner_orig=$(stat -c %U $FILE)
        chown $USER $FILE
        "$code" $FILE --wait
        chown $owner_orig $FILE
        echo "owner was $owner_orig"
    else
    echo "not a file"
    fi
else usage
fi

