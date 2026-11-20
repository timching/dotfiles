# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/) + [Nix Home Manager](https://github.com/nix-community/home-manager) for cross-platform package management.

## Quick start (any platform)

```bash
# 1. Install chezmoi & apply dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply timching

# 2. Run bootstrap (installs nix, home-manager, and all packages)
bash ~/.local/share/chezmoi/bootstrap.sh
```

## Platform-specific notes

### macOS

Brew is used for macOS-only GUI apps (casks) and tools not available in nixpkgs.

```bash
# Install Homebrew (bootstrap.sh does this automatically)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install brew packages & casks
brew bundle --file=~/.local/share/chezmoi/Brewfile --no-lock
```

### Ubuntu / Debian

No extra steps — `bootstrap.sh` handles everything via Nix. If you need system packages:

```bash
sudo apt update && sudo apt install -y curl git zsh
chsh -s $(which zsh)
```

### SteamOS

SteamOS has a read-only root filesystem. Nix works perfectly here since it installs to `/nix` without touching system files.

```bash
# Enable read-write (temporary, resets on update)
sudo steamos-readonly disable

# Install dependencies
sudo pacman -S curl git

# Re-enable read-only
sudo steamos-readonly enable

# Then run the quick start steps above — nix & chezmoi install to user space
```

### Bazzite OS / Fedora Atomic (uBlue)

Immutable filesystem — avoid `rpm-ostree` for dev tools. Nix is the ideal solution here.

```bash
# Install dependencies via rpm-ostree (persists across updates)
rpm-ostree install curl git zsh
systemctl reboot

# Then run the quick start steps above
```

### Arch Linux

```bash
sudo pacman -S curl git zsh
chsh -s $(which zsh)

# Then run the quick start steps above
```

### Fedora / RHEL

```bash
sudo dnf install -y curl git zsh
chsh -s $(which zsh)

# Then run the quick start steps above
```

## Codex status line

The [Codex status-line backup](.codex/statusline.toml) stores the item order and color preference.
To restore it, merge its two keys into the `[tui]` table in `~/.codex/config.toml`.
If the table is missing, add the whole snippet. After changing the status line in
Codex, copy those two settings back into the backup.

## Day-to-day usage

Edit dotfiles at their home-relative paths in this repo, such as `.vimrc` or
`.claude/statusline-command.sh`. To manage another file, save it here and add
its path to the [chezmoi file list](chezmoi/.chezmoiexternal.toml.tmpl).
Use `chezmoi diff ~/.vimrc` to preview a Vim change and `chezmoi apply ~/.vimrc`
to install it.

`.chezmoiroot` points chezmoi to the `chezmoi/` directory for its installation
rules. The two `private_` directories there keep `~/.claude` and `~/.config`
at mode `0700`.

If you edited the home copy, copy it back to the matching path in this repo
before committing, e.g. `cp ~/.vimrc ~/.local/share/chezmoi/.vimrc`.

```bash
# See what would change
chezmoi diff

# Apply changes from source
chezmoi apply

# Pull latest and apply
chezmoi update

# Add a new CLI tool
# 1. Edit ~/.config/home-manager/home.nix
# 2. Run: home-manager switch
# 3. Run: /update-dotfiles (in Claude Code) to sync config files

# Commit & push changes
cd ~/.local/share/chezmoi
git add .
git commit -m "your message"
git push
```
