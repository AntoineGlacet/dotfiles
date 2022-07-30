#!/bin/bash
############################
# dotfiles.sh
# This script install or uninstall dotfiles
# Shamelessly stolen from https://github.com/reenjii/dotfiles.git
############################

########## Variables

# dotfiles folder
DOTFILES="$HOME/dotfiles"
BACKUP="$DOTFILES/backup"

# ohmyzsh install folder
OH_MY_ZSH="$HOME/.oh-my-zsh"

# if running on WSL
# if [[ $(uname -a) == *"WSL"* ]];
# then

#     echo "WSL detected, symlinking between windows and WSL"
#     # add cmd.exe to PATH
#     export PATH=$PATH:/mnt/c/WINDOWS/system32/

#     IFS='\'
#     read -ra AD <<< $(cd /mnt/c && cmd.exe /c "echo %APPDATA%")
#     read -ra LD <<< $(cd /mnt/c && cmd.exe /c "echo %LOCALAPPDATA%")
#     read -ra UP <<< $(cd /mnt/c && cmd.exe /c "echo %USERPROFILE%")

#     APPDATA="/mnt/c/${AD[1]}/${AD[2]}/${AD[3]}/${AD[4]}"
#     LOCALAPPDATA="/mnt/c/${LD[1]}/${LD[2]}/${LD[3]}/${LD[4]}"
#     USERPROFILE="/mnt/c/${UP[1]}/${UP[2]}"

#     APPDATA=${APPDATA::-1}
#     LOCALAPPDATA=${LOCALAPPDATA::-1}
#     USERPROFILE=${USERPROFILE::-1}

# fi

##########

########## Functions

# Check that a given command exists
need_cmd() {
    if ! hash "$1" &>/dev/null; then
        error "$1 is needed (command not found)"
        exit 1
    fi
    success "$1 check"
}

### Display
COLOR_OFF='\033[0m' # Text Reset
RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
msg() { printf '%b\n' "$1" >&2; }
success() { msg "${GREEN}[✔]${COLOR_OFF} $1"; }
info() { msg "${BLUE}[ℹ]${COLOR_OFF} $1"; }
warn() { msg "${RED}[✘]${COLOR_OFF} $1"; }
error() {
    msg "${RED}[✘]${COLOR_OFF} $1"
    exit 1
}

# Clones or updates a git repository
# $1 = repository
# $2 = directory absolute path
function fetch_repo {
    local repo=$1
    local dir=$2
    if [[ -d "$dir" ]]; then
        info "Update $dir"
        git -C "$dir" pull
    else
        info "Clone $repo"
        git clone --depth=1 "$repo" "$dir"
    fi
}

# Creates a symbolic link
# $1 = target
# $2 = link name
function make_link {
    local target=$1
    local linkname=$2
    if [[ -L "$linkname" ]]; then
        local linktarget
        linktarget=$(readlink "$linkname")
        if [[ "$linktarget" != "$target" ]]; then
            warn "$linkname is a symbolic link to $linktarget but should target $target instead"
        else
            success "$linkname config file"
        fi
    else
        if [[ -e "$linkname" ]]; then
            warn "$linkname already exists but is not a symbolic link"
            warn "Please remove $linkname to install $target config file"
        else
            info "Install $target config file"
            ln -v -s "$target" "$linkname"
        fi
    fi
}

# Deletes a symbolic link
# $1 = target
# $2 = link name
function unmake_link {
    local target=$1
    local linkname=$2
    if [[ -L "$linkname" ]]; then
        local linktarget
        linktarget=$(readlink "$linkname")
        if [[ "$linktarget" =~ $target ]]; then
            rm -v "$linkname"
            success "Removed $target config file"
        fi
    fi
}

# move to backup with timestamp
# $1 = target
function backup {
    local target=$1
    if [[ -e "$target" ]]; then
        basename=$(basename "$target")
        cp -L "$target" "$BACKUP/$(date +%y%m%d_%H%M%S).$basename"
        rm "$target"
    fi
}

##########

########## Script
usage() {
    echo "dotfiles install script"
    echo ""
    echo "Usage : dotfiles (install|uninstall)"
}

if [[ $# -gt 0 ]]; then
    case $1 in
    install | i)
        info "Install dotfiles"

        # Needed commands
        need_cmd 'git'
        need_cmd 'curl'
        need_cmd 'ln'

        # Install or update required programs (zsh, oh-my-zsh & plugins)
        # zsh
        if ! grep -q zsh /etc/shells; then # test if zsh is a shell
            info "installing zsh..."
            sudo apt --yes update
            sudo apt --yes install zsh
        else
            success "zsh check"
        fi
        # mc
        if ! hash "mc" &>/dev/null; then
            info "installing mc..."
            sudo apt --yes update
            sudo apt --yes install mc
        else
            success "mc check"
        fi

        # should be modified to follow recommended install method
        # Install oh-my-zsh
        fetch_repo "git://github.com/ohmyzsh/ohmyzsh.git" "$OH_MY_ZSH"
        # Install powerlevel10k for zsh
        fetch_repo https://github.com/romkatv/powerlevel10k.git "$OH_MY_ZSH/custom/themes/powerlevel10k"
        # Install zsh-syntax-highlighting
        fetch_repo https://github.com/zsh-users/zsh-syntax-highlighting.git "$OH_MY_ZSH/custom/plugins/zsh-syntax-highlighting"
        # Install zsh-autosuggestions
        fetch_repo https://github.com/zsh-users/zsh-autosuggestions "$OH_MY_ZSH/custom/plugins/zsh-autosuggestions"
        make_link "$DOTFILES/oh-my-zsh/custom/zsh-autosuggestions.zsh" "$OH_MY_ZSH/custom/zsh-autosuggestions.zsh"

        # Install exa
        # different for rpi and others, just wait ubuntu 22.04 LTS
        # then, there will be packet manager

        # Symbolic link for shell folder
        make_link "$DOTFILES/shell" "$HOME/.shell"

        # Symbolic links for files in shell folder
        backup "$HOME/.bashrc"
        make_link "$DOTFILES/shell/bashrc" "$HOME/.bashrc"
        backup "$HOME/.zshrc"
        make_link "$DOTFILES/shell/zshrc" "$HOME/.zshrc"

        # git
        backup "$HOME/.gitconfig"
        make_link "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"

        # mc
        for file in "$DOTFILES/mc/config"/*; do
            fname=$(basename "$file")
            backup "$HOME/.config/mc/${fname}"
            make_link "$file" "$HOME/.config/mc/${fname}"
        done

        # mc skin (edited dracula)
        mkdir -p "$HOME/.local/share/mc/skins"
        cp "$DOTFILES/mc/skins/dracula256.ini" "$HOME/.local/share/mc/skins/"

        # scripts
        for file in "$DOTFILES/scripts"/*; do
            fname=$(basename "$file")
            backup "$HOME/.local/bin/${fname}"
            make_link "$file" "$HOME/.local/bin/${fname}"
        done

        # windows
        # does not work
        # if [[ $(uname -a) == *"WSL"* ]];
        # then
        # windows terminal
        # vscode is just auto sync
        # fi

        info "Install complete"
        exit 0
        ;;
    uninstall | u)
        info "Uninstall dotfiles"

        # Needed commands
        need_cmd 'git'
        need_cmd 'curl'
        need_cmd 'ln'

        # We leave oh-my-zsh repo

        # Symbolic link for shell folder
        unmake_link "$DOTFILES/shell" "$HOME/.shell"

        # Symbolic links for files in shell folder
        unmake_link "$DOTFILES/shell/bashrc" "$HOME/.bashrc"
        unmake_link "$DOTFILES/shell/zshrc" "$HOME/.zshrc"

        info "Uninstall complete"
        exit 0
        ;;
    --help | -h)
        usage
        exit 0
        ;;
    *)
        usage
        exit 0
        ;;
    esac
fi

usage
