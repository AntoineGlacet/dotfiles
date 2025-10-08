# Dotfiles automation

This repository contains the dotfiles and bootstrap scripts I use to quickly
provision a terminal-focused development environment on Ubuntu and WSL.
Everything is wired around the `dotfiles.sh` installer, which sets up the shell,
terminal tooling, language runtimes, and supporting configuration files via
symlinks. A companion PowerShell script keeps Windows Terminal in sync when I am
on Windows.

> **Supported platforms**
>
> The automation targets Debian-based distributions with `apt`. The install path
> has been tested primarily on Ubuntu and on Ubuntu running inside WSL. The
> script contains guards so that it can be run safely on macOS or other Linux
> distributions, but package installation is Ubuntu-specific.

## Repository layout

```
.
├── dotfiles.sh                # Linux / WSL bootstrap entry point
├── dotfiles.ps1               # Windows helper for Terminal settings
├── shell/                     # Shared shell snippets for Bash & Zsh (Powerlevel10k profile)
├── git/gitconfig              # Git defaults
├── tmux/.tmux.conf            # tmux configuration and plugin manager setup
├── mc/                        # Midnight Commander preferences and Dracula skin
├── scripts/                   # Utility scripts available via ~/.local/bin
├── windows/                   # Windows Terminal profile JSON, optional extras
└── backup/                    # Created on demand; previous dotfiles are copied here
```

## What the installer does

Running `./dotfiles.sh install` now supports two profiles:

- **extended** *(default)* – provisions the full development toolbox (Docker,
  language runtimes, pnpm) alongside the dotfiles.
- **core** – keeps the configuration lean and skips the heavy tooling so you can
  add languages and runtimes manually later.

Regardless of the profile, the installer:

1. **Validates required base commands** – ensures `git`, `curl`, `ln`, `wget`,
   `gpg`, and `tee` are available before proceeding.
2. **Installs Ubuntu packages (when `apt` is present)** – installs:
   - `zsh`, `mc`, and `direnv` for shell enhancements.
   - Build tooling and libraries needed by `pyenv`
     (`build-essential`, `libssl-dev`, `zlib1g-dev`, `libbz2-dev`,
     `libreadline-dev`, `libsqlite3-dev`, `libncursesw5-dev`, `xz-utils`, `tk-dev`,
     `libxml2-dev`, `libxmlsec1-dev`, `libffi-dev`, `liblzma-dev`).
   - `python3-pip` for general Python package management.
   - Docker Engine and CLI if they are not already installed.
   - The [eza](https://eza.rocks/) modern `ls` replacement (added via the official
     upstream apt repository if missing).
3. **Sets up Docker** – creates the `docker` group when necessary, adds the
   current user to that group, and enables the Docker service if `systemd`
   controls it. The script reminds you to log out/in (or run `newgrp docker`) so
   the new group membership takes effect.
4. **Bootstraps the Zsh runtime** – installs or updates the
   [zinit](https://github.com/zdharma-continuum/zinit) plugin manager, enables
   cached completions, and loads the same plugin/theme stack that previously
   lived in Oh My Zsh:
   - [powerlevel10k](https://github.com/romkatv/powerlevel10k) theme
   - [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
   - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
   - Oh My Zsh `golang` and `z` plugins (loaded directly via zinit snippets)
5. **Creates symlinks to dotfiles** – backs up any existing files into
   `backup/` (timestamped copies) before linking the repository versions:
   - Shell: `~/.shell`, `~/.bashrc`, `~/.zshrc`, and `~/.p10k.zsh`.
   - Git: `~/.gitconfig`.
   - Midnight Commander: files in `~/.config/mc/` and a Dracula skin in
     `~/.local/share/mc/skins/`.
   - Scripts: every file in `scripts/` is linked into `~/.local/bin/`.
   - tmux: `~/.tmux.conf` including plugin manager bootstrap.
6. **Changes the default shell to Zsh** – when not already the default, the
   script runs `chsh` under sudo. On WSL this step is skipped and a reminder is
   printed, because `chsh` frequently fails inside WSL without additional setup.


When the **extended** profile is selected, the script performs additional
bootstrap tasks:

- **Installs extra Ubuntu tooling** – adds `python3-pip` along with the build
  dependencies that `pyenv` needs (`build-essential`, `libssl-dev`, `zlib1g-dev`,
  `libbz2-dev`, `libreadline-dev`, `libsqlite3-dev`, `libncursesw5-dev`,
  `xz-utils`, `tk-dev`, `libxml2-dev`, `libxmlsec1-dev`, `libffi-dev`,
  `liblzma-dev`). If Docker Engine/CLI are missing they are installed from the
  official repository.
- **Configures Docker** – creates the `docker` group when necessary, adds the
  current user to that group, and enables the Docker service if `systemd`
  controls it. A reminder prompts you to log out/in (or run `newgrp docker`) so
  the new group membership takes effect.
- **Installs direnv** – installs `direnv` via `apt` on Ubuntu systems (other
  platforms receive a warning so you can install it manually).
- **Bootstraps language tooling** – installs `pyenv`, ensures Python `3.12.2`
  is present and set as the global interpreter, installs `nvm`, makes Node.js
  `20.11.1` the default, and installs `pnpm` when it is not already available.

When all steps finish successfully, the script prints `Install complete`and
shows where the run was logged (`backup/dotfiles-install.log`).


### Midnight Commander theme

The installer copies the custom Dracula-inspired skin to
`~/.local/share/mc/skins/dracula256.ini`. After the first launch of Midnight
Commander (`mc`), choose the skin from the options menu if it is not selected
automatically.

### Utility scripts

`scripts/chown_vscode_chown` (symlinked as `~/.local/bin/chown_vscode_chown`)
provides the `kk` helper. Invoke it as:

```bash
kk /etc/some/protected.conf
```

The script temporarily changes ownership of the target file, opens it in VS Code
with `code --wait`, and restores the original ownership when VS Code exits. It is
handy for editing system files without running the editor as root.

### Modern `ls` defaults

Interactive shells alias `ls` to
[`eza`](https://github.com/eza-community/eza) with icons, Git status, and
directories grouped first so that the enhanced view becomes the default. Helper
aliases such as `ll`, `la`, `lt`, and `lg` expose common combinations (long
listing, hidden files, tree view, and Git-aware listings respectively). If you
prefer a pure ASCII listing, run the aliases with `--no-icons` (for example,
`ls --no-icons`) or adjust the alias in `shell/aliases` to drop the `--icons`
flag.

## Ubuntu- and WSL-specific behaviour

- **Package manager** – all package installation uses `apt`. On WSL ensure the
  Microsoft Store Ubuntu distribution has been initialized and is up to date
  (`sudo apt update && sudo apt upgrade`) before running the installer.
- **Docker in WSL** – Docker Engine will only work inside WSL if the necessary
  kernel components are available. On Windows 11 with WSL 2, install
  [Docker Desktop](https://www.docker.com/products/docker-desktop/) or enable the
  WSL2 backend and ensure the Linux distribution has systemd support. The script
  still configures group membership so that Docker commands can run without
  `sudo` once the engine is available.
- **Default shell on WSL** – the installer does **not** run `chsh` when it
  detects WSL. To make Zsh the login shell manually, run:
  ```bash
  sudo chsh -s "$(command -v zsh)" "$USER"
  ```
  You can alternatively configure Windows Terminal to start Zsh by default in
  the Ubuntu profile (see below).
- **Fonts** – the prompt theme expects the "CaskaydiaCove Nerd Font" (patched
  Cascadia Code). On Windows install the font from the `fonts/` directory or
  download it from [Nerd Fonts](https://www.nerdfonts.com/font-downloads), then
  select it in Windows Terminal. On Linux you can copy the `.ttf` files to
  `~/.local/share/fonts/` and run `fc-cache -f`.

## Windows companion setup

The PowerShell script `dotfiles.ps1` helps keep Windows Terminal settings in
sync. Run it from an elevated PowerShell prompt:

```powershell
Set-ExecutionPolicy -Scope Process RemoteSigned
./dotfiles.ps1
```

The script automatically locates the appropriate Windows Terminal configuration
directory (supports both the Microsoft Store and unpackaged installations) and
creates a symbolic link to `windows/terminal/settings.json`. If the directory is
not found, it prints guidance to launch Windows Terminal once so the settings
folder is created before re-running the script.

## Installation instructions

> **Tip:** The installer determines its own directory at runtime, so you can
> clone the repository anywhere (not just `~/dotfiles`) and run the script from
> that location.

1. Clone the repository (pick any directory you prefer):
   ```bash
   git clone https://github.com/<you>/dotfiles.git /path/to/your/clone/dotfiles
   cd /path/to/your/clone/dotfiles
   ```
2. Make sure the installer is executable:
   ```bash
   chmod +x dotfiles.sh
   ```
3. Run the installer (defaults to the `extended` profile). Pass
   `--profile core` if you want to skip Docker and the language runtimes:
   ```bash
   ./dotfiles.sh install
   # or
   ./dotfiles.sh install --profile core
   ```
4. Follow any prompts in the terminal (e.g., logging out/in for Docker group
   membership when using the extended profile). Restart your shell after
   installation so that pyenv, nvm, pnpm, and the new Zsh configuration are
   loaded.


## Uninstalling

To remove the symlinks that point to this repository and revert the default
shell to Bash, run:

```bash
./dotfiles.sh uninstall
```

The uninstall command removes links to `~/.shell`, `~/.bashrc`, and `~/.zshrc`.
It also attempts to switch your login shell back to Bash (skipping `chsh` on
WSL and when passwordless sudo is not available).

Backups of files that were replaced during installation remain in the
`backup/` directory. You can manually restore them if required.

## Customising the setup

- Update versions: adjust `PYTHON_VERSION` and `NODE_VERSION` at the top of
  `dotfiles.sh` before running the installer.
- Extend the package list: edit the `apt install` section inside the Ubuntu
  branch.
- Add more scripts: place executable files in `scripts/` and they will be linked
  into `~/.local/bin` on the next run.
- Zsh plugins: edit the `zinit` section in `shell/zshrc` to add or remove
  plugins and snippets.
- Prompt styling: adjust `shell/p10k.zsh` (linked to `~/.p10k.zsh`) or run
  `p10k configure` from within Zsh to regenerate the theme profile.

## Troubleshooting tips

- If zinit reports issues updating plugins, re-run the installer or execute
  `zinit self-update && zinit update` from within Zsh.
- Docker commands failing with `permission denied` usually mean the new group
  membership has not been applied yet. Log out/in or run `newgrp docker`.
- When running under WSL without systemd, enabling the Docker service will fail;
  the script reports this as a warning. Install Docker Desktop or enable systemd
  to manage the service automatically.

Feel free to fork the repository and tailor it to your own workflow.
