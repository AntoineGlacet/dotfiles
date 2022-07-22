#!/bin/bash

# if running on WSL
if [[ $(uname -a) == *"WSL"* ]];
then

    echo "WSL detected, symlinking between windows and WSL"
    # add cmd.exe to PATH
    export PATH=$PATH:/mnt/c/WINDOWS/system32/

    IFS='\'
    read -ra AD <<< $(cd /mnt/c && cmd.exe /c "echo %APPDATA%")
    read -ra LD <<< $(cd /mnt/c && cmd.exe /c "echo %LOCALAPPDATA%")
    read -ra UP <<< $(cd /mnt/c && cmd.exe /c "echo %USERPROFILE%")

    APPDATA="/mnt/c/${AD[1]}/${AD[2]}/${AD[3]}/${AD[4]}"
    LOCALAPPDATA="/mnt/c/${LD[1]}/${LD[2]}/${LD[3]}/${LD[4]}"
    USERPROFILE="/mnt/c/${UP[1]}/${UP[2]}"

    APPDATA=${APPDATA::-1}
    LOCALAPPDATA=${LOCALAPPDATA::-1} 
    USERPROFILE=${USERPROFILE::-1}

    echo $APPDATA
    echo $LOCALAPPDATA
    echo $USERPROFILE

fi

echo $(ls $APPDATA)

