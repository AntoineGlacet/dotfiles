#!/bin/bash
############################
# dotfiles.sh
# This script install or uninstall dotfiles
# Shamelessly stolen from https://github.com/reenjii/dotfiles.git
############################

########## Variables

# dotfiles folder
DOTFILES="$HOME/dotfiles"

# ohmyzsh config folder
OH_MY_FISH="$HOME/.config/omf"

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

# Display
COLOR_OFF='\033[0m' # Text Reset
RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
msg()      { printf '%b\n' "$1" >&2; }
success() { msg "${GREEN}[✔]${COLOR_OFF} $1"; }
info()    { msg "${BLUE}[ℹ]${COLOR_OFF} $1"; }
warn()    { msg "${RED}[✘]${COLOR_OFF} $1"; }
error()   { msg "${RED}[✘]${COLOR_OFF} $1"; exit 1; }

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
        local linktarget=$(readlink "$linkname")
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
        local linktarget=$(readlink "$linkname")
        if [[ "$linktarget" =~ "$target" ]]; then
            rm -v "$linkname"
            success "Removed $target config file"
        fi
    fi
}
##########


########## Script

if [[ $# -gt 0 ]]; then
    case $1 in
        install|i)
            info "Install dotfiles"

            # Needed commands
            need_cmd 'git'
            need_cmd 'curl'
            need_cmd 'ln'

            # Install or update required programs (fish and oh-my-fish)

            # Symbolic links for files of oh-my-fish
            make_link "$DOTFILES/oh-my-fish/init.fish" "$OH_MY_FISH/init.fish"

            # git, vscode, others


            info "Install complete"
            exit 0
            ;;
        uninstall|u)
            info "Uninstall dotfiles"

            # Needed commands
            need_cmd 'git'
            need_cmd 'curl'
            need_cmd 'ln'

            # uninstall installed stuff

            # Symbolic links for files of oh-my-fish
            unmake_link "$DOTFILES/oh-my-fish/init.fish" "$OH_MY_FISH/init.fish"

            # git, vscode, others


            info "Uninstall complete"
            exit 0
            ;;
        --help|-h)
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

##########