{ config, pkgs, ... }:

{
  home.username = "timching";
  home.homeDirectory = "/Users/timching";
  home.stateVersion = "25.11";

  # ── Packages ──
  home.packages = with pkgs; [
    # Shell & terminal
    (vim-full.customize {
      name = "vim";
      vimrcConfig.customRC = ""; # uses your existing ~/.vimrc
    })
    neovim
    btop
    htop
    tree
    fzf
    lazygit
    viddy
    hwatch

    # Dev tools
    go
    php
    elixir
    python3
    bun
    pipx
    mise
    bison

    # Rust (installed via rustup, but cargo/rustc available)
    # rustup  # manage separately — uses ~/.cargo

    # HTTP & API
    httpie
    wrk
    wget

    # Cloud & infra
    kubectl
    kubernetes-helm
    pulumi
    doctl
    rclone
    s3cmd

    # Media & conversion
    vips
    imagemagick
    ffmpeg
    libwebp    # cwebp

    # Docs & content
    hugo
    pandoc
    mercurial

    # Security & network
    gnupg
    arp-scan
    age

    # Reverse engineering & testing
    jadx
    jmeter

    # Dotfiles
    chezmoi

    # Android
    scrcpy
  ];

  home.sessionVariables = {
    EDITOR = "vim";
  };

  programs.home-manager.enable = true;
}
