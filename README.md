# dotfiles

Repo with my dotfiles configurations

Script dotfiles can install and uninstall dotfiles

## Pre-requisite

CaskaydiaCode NF

### Installing eza on Ubuntu

```bash
sudo apt update
sudo apt install -y gpg
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza
```

```
dotfiles
├── README.md
├── backup
├── dotfiles.sh
├── oh-my-zsh
│   └── custom
│       └── zsh-autosuggestions.zsh   <- config for autosuggestion
└── shell
    ├── aliases
    ├── bash_profile
    ├── bashrc
    ├── colors
    ├── env
    ├── env_functions
    ├── interactive
    └── zshrc
```

to do:

- [x] install zsh script
- [x] preserve old files in backup and restore with uninstall
- [ ] test on new install
- [ ] cleanup and use on main machine
- [ ] requires & install caskadya code
- [ ] copy p10k.zsh
- [ ] if WSL, symlink wsl.conf resolv.conf etc...
- [ ] update tree
- [ ] test on new user for rpi
