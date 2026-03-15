#!/bin/bash
set -e

echo "=== Installing Nix ==="
if ! command -v nix &>/dev/null; then
  sh <(curl -L https://nixos.org/nix/install)
  echo "Restart your terminal, then re-run this script."
  exit 0
fi

echo "=== Installing Home Manager ==="
if ! command -v home-manager &>/dev/null; then
  nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
  nix-channel --update
  nix-shell '<home-manager>' -A install
fi

echo "=== Applying Home Manager packages ==="
home-manager switch

echo "=== Installing Homebrew (macOS only) ==="
if [[ "$OSTYPE" == darwin* ]] && ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "=== Installing brew-only packages (macOS) ==="
if command -v brew &>/dev/null; then
  brew bundle --file="$(chezmoi source-path)/Brewfile" --no-lock
fi

echo "=== Installing Oh My Zsh ==="
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "=== Installing version managers ==="
# nvm (via zsh-nvm plugin — auto-installs on first shell load)

# gvm
if [ ! -d "$HOME/.gvm" ]; then
  bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
fi

# rustup
if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# bun
if ! command -v bun &>/dev/null; then
  curl -fsSL https://bun.sh/install | bash
fi

echo "=== Installing npm globals ==="
if command -v npm &>/dev/null; then
  npm i -g pnpm @fission-ai/openspec
fi

echo "=== Done! ==="
echo "Restart your terminal for all changes to take effect."
