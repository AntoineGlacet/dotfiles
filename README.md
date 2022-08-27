# dotfiles

Repo with my dotfiles configurations

Script dotfiles can install and uninstall dotfiles

## Pre-requisite

CaskaydiaCode NF

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
