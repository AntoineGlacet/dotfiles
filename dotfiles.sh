#!/bin/bash
############################
# dotfiles.sh
# Install or uninstall dotfiles and tooling
############################

########## Variables

DOTFILES="$HOME/dotfiles"
BACKUP="$DOTFILES/backup"
OH_MY_ZSH="$HOME/.oh-my-zsh"

########## Display Helpers

COLOR_OFF='\033[0m'
RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
msg() { printf '%b\n' "$1" >&2; }
success() { msg "${GREEN}[✔]${COLOR_OFF} $1"; }
info() { msg "${BLUE}[ℹ]${COLOR_OFF} $1"; }
warn() { msg "${RED}[✘]${COLOR_OFF} $1"; }
error() { msg "${RED}[✘]${COLOR_OFF} $1"; exit 1; }

########## Helpers

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error "$1 is needed (command not found)"
    fi
    success "$1 check"
}

get_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    echo "$OS" "$VER"
}

fetch_repo() {
    local repo=$1
    local dir=$2
    if [[ -d "$dir" ]]; then
        info "Updating $dir"
        git -C "$dir" pull --ff-only
    else
        info "Cloning $repo"
        git clone --depth=1 "$repo" "$dir"
    fi
}

make_link() {
    local target=$1
    local linkname=$2

    if [[ -L "$linkname" ]]; then
        if [[ $(readlink "$linkname") == "$target" ]]; then
            success "$linkname already correct"
        else
            warn "$linkname points elsewhere"
        fi
    elif [[ -e "$linkname" ]]; then
        warn "$linkname exists and is not a symlink"
    else
        info "Linking $linkname → $target"
        ln -vs "$target" "$linkname"
    fi
}

unmake_link() {
    local target=$1
    local linkname=$2
    [[ -L "$linkname" && $(readlink "$linkname") =~ $target ]] && rm -v "$linkname" && success "Removed $linkname"
}

backup() {
    local target=$1
    if [[ -e "$target" ]]; then
        mkdir -p "$BACKUP"
        cp -L "$target" "$BACKUP/$(date +%y%m%d_%H%M%S).$(basename "$target")"
        rm -f "$target"
    fi
}

install_eza() {
    sudo apt update
    sudo apt install -y gpg wget
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
}

install_oh_my_zsh() {
    if [[ ! -d "$OH_MY_ZSH" ]]; then
        info "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        success "Oh My Zsh already installed"
    fi
}

########## Script Entry Point

usage() {
    echo -e "\nUsage: dotfiles.sh (install|uninstall|--help)\n"
}

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

case $1 in
install | i)
    info "Installing dotfiles and tools"

    # Check required commands
    for cmd in git curl ln wget gpg; do
        need_cmd "$cmd"
    done

    os=$(get_os | awk '{print $1}')

    if [[ "$os" == "Ubuntu" ]]; then
        sudo apt update
        sudo apt install -y zsh mc python3-pip build-essential libssl-dev zlib1g-dev \
            libbz2-dev libreadline-dev libsqlite3-dev curl libncursesw5-dev xz-utils \
            tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

        if ! command -v eza &>/dev/null; then
            install_eza
        else
            success "eza check"
        fi
    fi

    install_oh_my_zsh

    # Plugins
    ZSH_CUSTOM=${ZSH_CUSTOM:-$OH_MY_ZSH/custom}
    fetch_repo https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    fetch_repo https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fetch_repo https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

    make_link "$DOTFILES/oh-my-zsh/custom/zsh-autosuggestions.zsh" "$ZSH_CUSTOM/zsh-autosuggestions.zsh"

    # Shell config
    make_link "$DOTFILES/shell" "$HOME/.shell"
    backup "$HOME/.bashrc"
    make_link "$DOTFILES/shell/bashrc" "$HOME/.bashrc"
    backup "$HOME/.zshrc"
    make_link "$DOTFILES/shell/zshrc" "$HOME/.zshrc"
    backup "$HOME/.p10k.zsh"
    make_link "$DOTFILES/oh-my-zsh/.p10k.zsh" "$HOME/.p10k.zsh"

    # Git config
    backup "$HOME/.gitconfig"
    make_link "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"

    # Midnight Commander
    mkdir -p "$HOME/.config/mc"
    for file in "$DOTFILES/mc/config"/*; do
        fname=$(basename "$file")
        backup "$HOME/.config/mc/$fname"
        make_link "$file" "$HOME/.config/mc/$fname"
    done
    mkdir -p "$HOME/.local/share/mc/skins"
    cp "$DOTFILES/mc/skins/dracula256.ini" "$HOME/.local/share/mc/skins/"

    # Scripts
    mkdir -p "$HOME/.local/bin"
    for file in "$DOTFILES/scripts"/*; do
        fname=$(basename "$file")
        backup "$HOME/.local/bin/$fname"
        make_link "$file" "$HOME/.local/bin/$fname"
    done

    # Tmux
    backup "$HOME/.tmux.conf"
    make_link "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"

    # direnv
    if ! command -v direnv &>/dev/null; then
        info "Installing direnv..."
        sudo apt install -y direnv
    else
        success "direnv check"
    fi

    # pyenv & pyenv-virtualenv
    if [[ ! -d "$HOME/.pyenv" ]]; then
        info "Installing pyenv..."
        curl https://pyenv.run | bash
    else
        success "pyenv already installed"
    fi

    # nvm
    if [[ ! -d "$HOME/.nvm" ]]; then
        info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    else
        success "nvm already installed"
    fi

    # pnpm
    if ! command -v pnpm &>/dev/null; then
        info "Installing pnpm..."
        curl -fsSL https://get.pnpm.io/install.sh | bash -
    else
        success "pnpm check"
    fi

    info "Install complete"

    ;;

uninstall | u)
    info "Uninstalling dotfiles"
    for cmd in git curl ln; do
        need_cmd "$cmd"
    done

    unmake_link "$DOTFILES/shell" "$HOME/.shell"
    unmake_link "$DOTFILES/shell/bashrc" "$HOME/.bashrc"
    unmake_link "$DOTFILES/shell/zshrc" "$HOME/.zshrc"

    info "Uninstall complete"
    ;;

--help | -h)
    usage
    ;;

*)
    usage
    exit 1
    ;;
esac
