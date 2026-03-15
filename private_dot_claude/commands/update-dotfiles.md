Audit and update my dotfiles package lists. Follow these steps:

## 1. Scan current installations

Run these commands to discover what's installed:

- `brew leaves` — top-level brew formulae
- `brew list --cask` — GUI apps
- `npm ls -g --depth=0` — npm globals
- `pipx list --short` — pipx packages
- `cargo install --list` — cargo packages
- `bun pm ls -g` — bun globals

## 2. Cross-reference with nixpkgs

For each installed tool, check if it's available in nixpkgs. Prefer nix for cross-platform CLI tools. Keep in brew only if:
- It's a macOS cask (GUI app)
- It's from a custom tap not in nixpkgs
- It's not available in nixpkgs

## 3. Update these 3 files

- `~/.config/home-manager/home.nix` — add/remove packages to match what's installed, prefer nix for cross-platform tools
- `~/.local/share/chezmoi/Brewfile` — only macOS casks + tools NOT available in nixpkgs
- `~/.local/share/chezmoi/bootstrap.sh` — update npm/pipx/cargo/bun globals sections to match current installs

## 4. Show diff summary

Before applying changes, show me a summary table of:
- New packages added (and to which file)
- Packages removed
- Packages moved between brew and nix

Wait for my approval before writing any files.

## 5. After approval

- Write the updated files
- Run `home-manager switch` to verify nix changes work
- Commit and push to dotfiles repo
