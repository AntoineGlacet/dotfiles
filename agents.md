# Agent Guidelines for Dotfiles Repository

## Purpose

This document provides guidelines for AI coding assistants (OpenCode, Cursor, GitHub Copilot, Claude, etc.) when working on this dotfiles repository. Following these guidelines ensures consistency, security, and maintainability.

## Repository Context

### What This Repo Does

- Automated dotfiles installation for Ubuntu/WSL environments
- Manages shell configuration (Bash, Zsh with zinit plugin manager)
- Installs and configures development tools (Docker, pyenv, nvm, pnpm, etc.)
- Provides utility scripts and aliases for common tasks
- Manages OpenCode configuration for AI coding assistants

### Tech Stack

- **Shell**: Bash 4.0+, Zsh 5.0+
- **Plugin Manager**: zinit (NOT Oh My Zsh - we migrated away)
- **Package Manager**: apt (Ubuntu/Debian)
- **Theme**: Powerlevel10k
- **Modern Tools**: eza, fzf, bat (batcat), fd (fdfind), ripgrep, tmux, mc
- **Version Managers**: pyenv (Python), nvm (Node.js), pnpm

## Coding Standards

### Shell Scripting

- **Style**: Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Error Handling**: Use `set -euo pipefail` for safety-critical scripts
- **Compatibility**: Bash 4.0+ for scripts, POSIX for maximum compatibility where needed
- **Linting**: All scripts must pass `shellcheck` without errors
- **Functions**: One purpose per function, clear descriptive naming
- **Comments**: Explain "why" not "what" - code should be self-documenting

### File Organization

```
dotfiles/
├── dotfiles.sh              # Main installer (monolithic by design)
├── shell/                   # Modular shell components
│   ├── env                  # PATH and general environment
│   ├── env.local           # Personal settings (git-ignored, see template)
│   ├── env.local.template  # Template for env.local
│   ├── env_functions       # Utility functions (proxy, path management)
│   ├── aliases             # Command aliases
│   ├── keybindings         # Shared key bindings
│   ├── interactive         # Interactive shell setup (fzf)
│   ├── bashrc              # Bash entry point
│   ├── zshrc               # Zsh entry point
│   ├── p10k.zsh            # Powerlevel10k theme configuration
│   └── colors              # Color definitions for prompts
├── git/                     # Git configuration
├── tmux/                    # tmux configuration
├── mc/                      # Midnight Commander config + theme
├── ssh/                     # SSH config template (no actual servers!)
├── opencode/                # OpenCode AI assistant configuration
├── htop/                    # htop system monitor configuration
├── scripts/                 # Utility scripts (symlinked to ~/.local/bin)
└── backup/                  # Auto-created during install, git-ignored
```

### Security Best Practices

1. **Never commit secrets**: tokens, passwords, API keys, personal IPs
2. **Use env.local**: Personal data goes in `shell/env.local` (git-ignored)
3. **Templates for sharing**: `*.template` files show structure without secrets
4. **Check before commit**: Review diffs for accidental token inclusion
5. **SSH configs**: Never commit private keys or actual server hostnames/IPs
6. **Environment variable references**: Use `{env:VAR_NAME}` in config files

## Common Tasks & Patterns

### Adding a New Tool

1. Add package installation to `install_ubuntu_packages()` in `dotfiles.sh:292`
2. Add aliases to `shell/aliases`
3. Add configuration directory and files
4. Update `dotfiles.sh` install section to symlink configs
5. Update README.md with new tool description and usage
6. Test on clean Ubuntu environment if possible

### Adding Environment Variables

- **General/Public**: Add to `shell/env`
- **Personal/Secret**: Document in `shell/env.local.template`, user adds to their `env.local`
- **Tool-specific**: Add to relevant section with explanatory comments

### Modifying Proxy Functions

- Proxy configuration is used in corporate environment (KAP network)
- Functions are defined in `shell/env_functions:68-176`
- Always test both enabled and disabled states
- Ensure `no_proxy` covers local networks: `192.168.0.0/16,10.0.0.0/8,172.16.0.0/12`
- SSH proxy uses `nc` (netcat) with `ProxyCommand` - don't change without testing
- Proxy settings use environment variables from `env.local`:
  - `KAP_PROXY_HOST` (default: 192.168.3.16)
  - `KAP_PROXY_PORT` (default: 8080)
  - `KAP_SOCKS_PORT` (default: 1080)

### Adding Aliases

- Check if command exists before aliasing: `command -v tool >/dev/null 2>&1`
- Group related aliases together with section comments (`# === Section ===`)
- Ubuntu renames some tools (`batcat`, `fdfind`) - handle gracefully with conditionals
- Document non-obvious aliases with inline comments
- See `shell/aliases:1-134` for examples

### Testing Changes

```bash
# Quick test (doesn't affect system)
shellcheck dotfiles.sh shell/bashrc shell/zshrc

# Specific file test
shellcheck shell/env_functions

# Full test (use VM/container or backup first)
./dotfiles.sh install --profile core
./dotfiles.sh install --profile extended
./dotfiles.sh uninstall
```

## Agent Behavior Guidelines

### What to Do ✅

- **Ask before major changes**: Architecture changes, new dependencies, breaking changes
- **Preserve backwards compatibility**: Existing installations should continue to work
- **Test on Ubuntu**: Primary target is Ubuntu 24.04 LTS (also test WSL compatibility)
- **Update documentation**: README.md, this file, inline comments
- **Explain trade-offs**: When multiple approaches exist, explain pros/cons
- **Follow existing patterns**: Match the coding style and organization
- **Shellcheck clean**: All scripts must pass linting before commit

### What NOT to Do ❌

- **Don't commit secrets**: Check EVERY file before commit for tokens, passwords, IPs
- **Don't break WSL**: Test WSL-specific behavior (chsh, systemd availability)
- **Don't assume tools exist**: Always check with `command -v` or `[[ -d ]]` first
- **Don't use Oh My Zsh**: We migrated to zinit for performance
- **Don't modify user's git config**: User manages their own git settings
- **Don't force push**: Unless explicitly requested for history rewrite (document why)
- **Don't remove backups**: The `backup/` directory is sacred
- **Don't hardcode personal data**: Use `env.local` for all personal/secret values

### When to Ask User

- Changing default installation profile (core vs extended)
- Adding new tools that require >100MB download
- Modifying installation order or dependencies
- Breaking changes to aliases or function signatures
- Adding new files that will be tracked in git
- Proxy configuration changes (affects corporate environment)
- Removing or deprecating existing features

## Tool Preferences

### Preferred Tools (Already Integrated)

- **ls replacement**: `eza` (not exa, lsd, or plain ls)
- **cat replacement**: `bat` (`batcat` on Ubuntu)
- **find replacement**: `fd` (`fdfind` on Ubuntu)
- **grep replacement**: `ripgrep` (command: `rg`)
- **fuzzy finder**: `fzf`
- **shell theme**: Powerlevel10k
- **editor**: VS Code (`code --wait`)
- **multiplexer**: `tmux` (not GNU screen)
- **file manager**: Midnight Commander (`mc`)
- **Python**: pyenv with version 3.12.2
- **Node**: nvm with version 20.11.1
- **Package manager**: pnpm (preferred over npm/yarn)

### Avoid These Tools

- **Oh My Zsh** - we use zinit for better performance
- **Antigen, Antibody** - we use zinit
- **rbenv** - not currently needed
- **screen** - use tmux instead
- **nano/pico** - user prefers VS Code

## Project-Specific Context

### KAP Corporate Environment

- Work network uses HTTP proxy (`192.168.3.16:8080`)
- SOCKS5 proxy available on port `1080`
- SSH requires `ProxyCommand nc` for external hosts
- Internal servers (`192.168.*`, `10.*`, `172.16-31.*`) bypass proxy
- Git operations need proxy for external repos (GitHub, GitLab)

### Personal Setup

- **Primary user**: Your Name
- **Work email**: antoine.glacet@kansai-airports.co.jp
- **Editor**: VS Code with `code --wait`
- **Primary OS**: Ubuntu 24.04 on WSL
- **Projects**: Data engineering, dbt, GCP BigQuery, OpenMetadata
- **OpenCode**: Configured with MCP servers for BigQuery and OpenMetadata

### Common Workflows

1. **Proxy toggle**: `pon` (enable) / `poff` (disable) / `ps` (status)
2. **Edit protected files**: `kk /etc/some/file` (chown + code + restore ownership)
3. **Git workflow**: VS Code as diff/merge tool
4. **Directory navigation**: `z` (jump to frecent directories), `fcd` (fzf-powered cd)
5. **File search**: `fd` for filenames, `rg` for content
6. **Process monitoring**: `h` (htop filtered to user)

## Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, no logic change)
- `refactor`: Code restructuring (no feature/fix)
- `perf`: Performance improvement
- `test`: Adding/updating tests
- `chore`: Maintenance tasks
- `security`: Security-related changes

### Scopes

- `shell`: Shell configuration (bashrc, zshrc, aliases)
- `git`: Git configuration
- `tmux`: tmux configuration
- `docker`: Docker setup
- `installer`: dotfiles.sh changes
- `docs`: README, this file
- `opencode`: OpenCode configuration
- `proxy`: Proxy-related functions

### Examples

```
feat(shell): add bat aliases for Ubuntu compatibility

Ubuntu installs bat as 'batcat' to avoid conflicts. Added conditional
aliases to handle both naming conventions gracefully.

Fixes #42
```

```
fix(installer): add conditional loading for pyenv

pyenv initialization was failing when core profile was used.
Added existence checks before eval to prevent errors.
```

```
security(env): move tokens to env.local

Removed hardcoded OPENMETADATA_MCP_TOKEN from zshrc.
Created env.local.template for users to add their own secrets.
Updated .gitignore to exclude env.local from version control.

BREAKING CHANGE: Users must create shell/env.local from template
```

```
docs(readme): document proxy functions

Added detailed explanation of proxy enable/disable/status commands
and their use in corporate environments.
```

## Git Workflow

### Branching Strategy

- `main`: Stable, tested configurations
- Feature branches: `feat/description` or `fix/description`
- Use pull requests for major changes (enables review and discussion)

### Before Committing

1. Run shellcheck on modified shell scripts
2. Test installation on clean environment (if possible)
3. Check diff for accidental secrets:
   ```bash
   git diff | grep -iE "token|password|secret|api[_-]?key"
   ```
4. Update README.md if usage or features changed
5. Add entry to commit message explaining changes

### Commit Checklist

- [ ] shellcheck passes on all modified `.sh` and shell config files
- [ ] No secrets, tokens, or personal IPs in diff
- [ ] Documentation updated (README.md, agents.md if needed)
- [ ] Tested changes don't break existing installations
- [ ] Commit message follows conventional commits format
- [ ] Related aliases/functions documented in code comments

## Testing & Quality

### Required Tests Before Commit

- [ ] `shellcheck dotfiles.sh` passes
- [ ] `shellcheck shell/*` passes (ignore errors in `p10k.zsh`)
- [ ] Installation works on Ubuntu 24.04 (if installer changed)
- [ ] Both profiles install successfully (core and extended)
- [ ] Uninstall removes symlinks correctly
- [ ] Proxy enable/disable works correctly (if proxy functions changed)

### Manual Test Checklist

```bash
# 1. Clone to temporary location
git clone <repo> /tmp/dotfiles-test
cd /tmp/dotfiles-test

# 2. Test core profile
./dotfiles.sh install --profile core
source ~/.zshrc
# Verify: zsh works, aliases work, no pyenv/nvm errors

# 3. Test extended profile
./dotfiles.sh uninstall
./dotfiles.sh install --profile extended
# Verify: docker, pyenv, nvm all work, env.local created

# 4. Test env.local setup
cat ~/.shell/env.local
# Should exist and contain template content

# 5. Cleanup
./dotfiles.sh uninstall
rm -rf /tmp/dotfiles-test
```

## Specific Implementation Notes

### Ubuntu vs Other Distributions

- **Package installation**: Only happens on Ubuntu (checks for `apt`)
- **Tool names**: Ubuntu renames `bat` → `batcat`, `fd` → `fdfind`
- **WSL detection**: `grep -qEi "(microsoft|wsl)" /proc/version`
- **systemd availability**: Check with `command -v systemctl`

### Shell Loading Order

1. **Zsh**: `~/.zshrc` → `~/.shell/env` → `~/.shell/env.local` → `~/.shell/aliases` → `~/.shell/keybindings`
2. **Bash**: `~/.bashrc` → `~/.shell/env` → `~/.shell/env.local` → `~/.shell/aliases` → `~/.shell/colors`

### Conditional Loading Pattern

Always check before initializing tools:

```bash
# Good
if [[ -d "$HOME/.pyenv" ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    eval "$(pyenv init -)"
fi

# Bad (will error if pyenv not installed)
eval "$(pyenv init -)"
```

### Alias Conditional Pattern

```bash
# Check if Ubuntu-named command exists but standard name doesn't
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    alias bat='batcat'
fi
```

## Questions to Ask Before Implementing

### New Features

- "Should this be in core or extended profile?"
- "Does this require sudo access?"
- "Is this tool available via apt?"
- "Will this work in WSL?"
- "What happens if this tool is not installed?"

### Modifications

- "Does this break existing installations?"
- "Should old config be backed up first?"
- "Do we need migration documentation?"
- "Is this a breaking change that needs user communication?"

### Dependencies

- "What's the download/install size?"
- "Is this critical or optional?"
- "Can we make it conditional/optional?"
- "Are there licensing concerns?"

## Useful References

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Zinit Documentation](https://github.com/zdharma-continuum/zinit)
- [Powerlevel10k Configuration](https://github.com/romkatv/powerlevel10k)
- [ShellCheck](https://www.shellcheck.net/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [OpenCode Documentation](https://opencode.ai/docs)

---

**Last Updated**: 2026-01-16  
**Maintained By**: Your Name  
**For AI Assistants**: Follow these guidelines strictly to maintain code quality and security
