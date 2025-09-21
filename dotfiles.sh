#!/bin/bash
############################
# dotfiles.sh
# Install or uninstall dotfiles and tooling
############################

########## Variables

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$DOTFILES/backup"
OH_MY_ZSH="$HOME/.oh-my-zsh"
PYTHON_VERSION="3.12.2"
NODE_VERSION="20.11.1"
PROFILE="extended"
DETECTED_OS=""
DETECTED_VERSION=""

LOG_DIR="$BACKUP"
LOG_FILE="$LOG_DIR/dotfiles-install.log"

if ! command -v tee >/dev/null 2>&1; then
    printf 'Error: required command "tee" not found in PATH.\n' >&2
    exit 1
fi

if ! mkdir -p "$LOG_DIR"; then
    printf 'Error: unable to create log directory %s\n' "$LOG_DIR" >&2
    exit 1
fi

exec > >(tee -a "$LOG_FILE") 2>&1

########## Display Helpers

COLOR_OFF='\033[0m'
RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
timestamp() { date '+%Y-%m-%d %H:%M:%S'; }
msg() { printf '%s %b\n' "[$(timestamp)]" "$1" >&2; }
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
    printf '%s\n%s\n' "$OS" "$VER"
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

install_ubuntu_packages() {
    local packages=(zsh mc)

    if [[ "$PROFILE" == "extended" ]]; then
        packages+=(python3-pip build-essential libssl-dev zlib1g-dev libbz2-dev \
            libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils tk-dev \
            libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev)
    fi

    if [[ ${#packages[@]} -gt 0 ]]; then
        sudo apt update
        sudo apt install -y "${packages[@]}"
    fi

    if ! command -v eza &>/dev/null; then
        install_eza
    else
        success "eza check"
    fi
}

ensure_docker() {
    if [[ "$DETECTED_OS" != "Ubuntu" ]]; then
        warn "Docker automation is only implemented for Ubuntu – skipping"
        return
    fi

    if ! command -v docker &>/dev/null; then
        info "Installing Docker..."
        sudo apt install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        # shellcheck disable=SC1091
        . /etc/os-release
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" \
            | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        success "docker check"
    fi

    if ! getent group docker &>/dev/null; then
        info "Creating docker group"
        sudo groupadd docker
    else
        success "docker group exists"
    fi

    if id -nG "$USER" | grep -qw docker; then
        success "User $USER already in docker group"
    else
        info "Adding $USER to docker group"
        sudo usermod -aG docker "$USER"
        warn "Log out and back in (or run 'newgrp docker') for group changes to apply"
    fi

    if command -v systemctl &>/dev/null; then
        if sudo systemctl is-enabled docker &>/dev/null; then
            success "docker service already enabled"
        else
            info "Enabling and starting docker service"
            if ! sudo systemctl enable --now docker; then
                warn "Unable to enable/start docker service automatically"
            fi
        fi
    else
        warn "systemctl not available – ensure Docker is started manually"
    fi
}

ensure_direnv() {
    if command -v direnv &>/dev/null; then
        success "direnv check"
        return
    fi

    if [[ "$DETECTED_OS" == "Ubuntu" ]]; then
        info "Installing direnv..."
        sudo apt install -y direnv
    else
        warn "direnv not installed – install manually for extended profile"
    fi
}

ensure_pyenv() {
    if [[ ! -d "$HOME/.pyenv" ]]; then
        info "Installing pyenv..."
        curl https://pyenv.run | bash
    else
        success "pyenv already installed"
    fi

    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    if [[ -x "$PYENV_ROOT/bin/pyenv" ]]; then
        if "$PYENV_ROOT/bin/pyenv" versions --bare | grep -qx "$PYTHON_VERSION"; then
            success "Python $PYTHON_VERSION already installed via pyenv"
        else
            info "Installing Python $PYTHON_VERSION via pyenv..."
            "$PYENV_ROOT/bin/pyenv" install -s "$PYTHON_VERSION"
        fi
        info "Setting global Python version to $PYTHON_VERSION"
        "$PYENV_ROOT/bin/pyenv" global "$PYTHON_VERSION"
    else
        warn "pyenv executable not found at $PYENV_ROOT/bin/pyenv"
    fi
}

ensure_nvm_node() {
    if [[ ! -d "$HOME/.nvm" ]]; then
        info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    else
        success "nvm already installed"
    fi

    export NVM_DIR="$HOME/.nvm"
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        # shellcheck disable=SC1090,SC1091
        . "$NVM_DIR/nvm.sh"
        if nvm ls "$NODE_VERSION" | grep -q "$NODE_VERSION"; then
            success "Node.js $NODE_VERSION already installed"
        else
            info "Installing Node.js $NODE_VERSION via nvm..."
            nvm install "$NODE_VERSION"
        fi
        nvm alias default "$NODE_VERSION"
        nvm use "$NODE_VERSION" >/dev/null
        success "Node.js $NODE_VERSION set as default"
    else
        warn "NVM initialization script not found"
    fi
}

ensure_pnpm() {
    if command -v pnpm &>/dev/null; then
        success "pnpm check"
    else
        info "Installing pnpm..."
        curl -fsSL https://get.pnpm.io/install.sh | bash -
    fi
}

install_extended_tooling() {
    info "Installing extended profile tooling"
    ensure_docker
    ensure_direnv
    ensure_pyenv
    ensure_nvm_node
    ensure_pnpm
}

########## Script Entry Point

usage() {
    cat <<'USAGE'

Usage:
  dotfiles.sh install [--profile core|extended]
  dotfiles.sh uninstall
  dotfiles.sh --help

The installer defaults to the "extended" profile.

USAGE
}

ACTION=""

while [[ $# -gt 0 ]]; do
    case $1 in
    install | i)
        if [[ -n "$ACTION" ]]; then
            error "Multiple actions specified"
        fi
        ACTION="install"
        shift
        ;;
    uninstall | u)
        if [[ -n "$ACTION" ]]; then
            error "Multiple actions specified"
        fi
        ACTION="uninstall"
        shift
        ;;
    --profile)
        if [[ $# -lt 2 ]]; then
            error "--profile requires a value (core or extended)"
        fi
        PROFILE=$(echo "$2" | tr '[:upper:]' '[:lower:]')
        shift 2
        ;;
    --profile=*)
        PROFILE=$(echo "${1#*=}" | tr '[:upper:]' '[:lower:]')
        shift
        ;;
    --help | -h)
        usage
        exit 0
        ;;
    *)
        error "Unknown argument: $1"
        ;;
    esac
done

if [[ -z "$ACTION" ]]; then
    usage
    exit 1
fi

case "$PROFILE" in
core | extended) ;;
*)
    error "Unknown profile: $PROFILE (expected 'core' or 'extended')"
    ;;
esac

if [[ "$ACTION" != "install" && "$PROFILE" != "extended" ]]; then
    error "--profile can only be used with the install command"
fi

case "$ACTION" in
install)
    info "Installing dotfiles and tools (profile: $PROFILE)"

    # Check required commands
    for cmd in git curl ln wget gpg tee; do
        need_cmd "$cmd"
    done

    mapfile -t os_info < <(get_os)
    DETECTED_OS=${os_info[0]}
    DETECTED_VERSION=${os_info[1]}

    if [[ "$DETECTED_OS" == "Ubuntu" ]]; then
        install_ubuntu_packages
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

    if [[ "$PROFILE" == "extended" ]]; then
        install_extended_tooling
    else
        info "Core profile selected – skipping Docker, language runtimes, and pnpm"
    fi

    # Set zsh as default shell if not already set
    if [[ "$SHELL" != "$(command -v zsh)" ]]; then
        if grep -qEi "(microsoft|wsl)" /proc/version; then
            warn "WSL detected – skipping chsh (manual shell switch required)"
        elif sudo -n true 2>/dev/null; then
            info "Changing default shell to zsh..."
            sudo chsh -s "$(command -v zsh)" "$USER"
        else
            warn "Passwordless sudo not available – skipping chsh"
        fi
    else
        success "zsh is already the default shell"
    fi

    info "Install complete"
    info "Install log saved to $LOG_FILE"

    ;;

uninstall)
    info "Uninstalling dotfiles"
    for cmd in git curl ln tee; do
        need_cmd "$cmd"
    done

    unmake_link "$DOTFILES/shell" "$HOME/.shell"
    unmake_link "$DOTFILES/shell/bashrc" "$HOME/.bashrc"
    unmake_link "$DOTFILES/shell/zshrc" "$HOME/.zshrc"

    # Reset shell to bash if needed
    if [[ "$SHELL" != "$(command -v bash)" ]]; then
        if grep -qEi "(microsoft|wsl)" /proc/version; then
            warn "WSL detected – skipping chsh to bash (manual shell switch required)"
        elif sudo -n true 2>/dev/null; then
            info "Reverting default shell to bash..."
            sudo chsh -s "$(command -v bash)" "$USER"
        else
            warn "Passwordless sudo not available – skipping chsh to bash"
        fi
    else
        success "bash is already the default shell"
    fi

    info "Uninstall complete"
    ;;
esac
