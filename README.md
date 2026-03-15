# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Setup on a new machine

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# Clone and apply dotfiles
chezmoi init --apply timching
```

## Usage

```bash
# Add a file
chezmoi add <file-path>

# See what would change
chezmoi diff

# Apply changes from source
chezmoi apply

# Pull latest and apply
chezmoi update

# Commit & push changes
cd ~/.local/share/chezmoi
git add .
git commit -m "your message"
git push
```
