{ config, pkgs, lib, ... }:

let
  # Everything links back into the repo working copy (not the nix store) so
  # configs stay hot-editable, exactly like the old install.sh symlinks.
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";

  inherit (pkgs.stdenv) isDarwin isLinux;

  # Side-by-side node majors, like nvm used to provide. `node` itself is the
  # default LTS in home.packages below; each major listed here additionally
  # gets suffixed binaries (node24, npm24, npx24). Entries are skipped (not
  # fatal) once nixpkgs drops or insecure-marks an EOL major -- unlike nvm,
  # nixpkgs doesn't carry end-of-life node: 18 is gone and 20 is flagged
  # insecure already.
  extraNodeMajors = [
    { pkg = pkgs.nodejs_24 or null; suffix = "24"; }
  ];
  nodeAliases = lib.concatMap
    ({ pkg, suffix }:
      map
        (bin: pkgs.writeShellScriptBin "${bin}${suffix}" ''exec "${pkg}/bin/${bin}" "$@"'')
        [ "node" "npm" "npx" ])
    (lib.filter (o: o.pkg != null && (builtins.tryEval o.pkg.outPath).success) extraNodeMajors);
in
{
  # Never change this after the first switch (it gates state migrations, not
  # the package versions -- those come from flake.lock).
  home.stateVersion = "25.05";

  # Provides the `home-manager` CLI after the first switch.
  programs.home-manager.enable = true;

  # Better login-shell/XDG integration when running on a non-NixOS distro.
  targets.genericLinux.enable = isLinux;

  # One package list for both macOS and Ubuntu. Replaces:
  #   programs/ubuntu/packages.sh (user-level portion), the formulae list in
  #   programs/mac/packages.sh, and the one-off installers for lazygit,
  #   neovim, lsd, tldr, dive, grpcurl, kubectl, starship, tmux, node (nvm),
  #   rust (rustup), bun, uv, and pipx.
  home.packages = with pkgs; [
    # core CLI tools
    bat
    btop
    cloudflared
    difftastic
    dive
    dnsutils
    fastfetch
    fd
    grpcurl
    htop
    httpie
    kubectl
    lazygit
    lsd
    nano
    ncdu
    neofetch # TODO: switch off neofetch (deprecated upstream)
    onefetch
    ripgrep
    tlrc
    unzip
    wireguard-tools

    # editors & multiplexer (tmux 3.5a in nixpkgs matches the version the old
    # from-source build pinned; both OSes stay on the identical release)
    neovim
    tmux

    # prompt
    starship

    # node -- replaces nvm + default-packages. `node` is LTS 22 (the old nvm
    # default); other supported majors get suffixed binaries via nodeAliases
    # above. EOL majors that nvm kept around (18, 20) are deliberately not
    # installed; when a legacy project needs one, borrow it from an older
    # nixpkgs release on demand:
    #   nix shell github:NixOS/nixpkgs/nixos-24.11#nodejs_20
    nodejs_22
    yarn

    # rust -- replaces rustup. On the work devbox, per-project toolchains
    # (nix develop / direnv) still take PATH precedence over these.
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer
    tree-sitter # was `cargo install tree-sitter-cli` (needed by nvim-treesitter)

    # python -- replaces python3-pip/pipx installs of these tools
    (python3.withPackages (ps: with ps; [ pip pynvim ]))
    pipx
    neovim-remote
    basedpyright

    # misc toolchains
    bun
    uv
  ] ++ nodeAliases ++ lib.optionals isLinux [
    # X11 clipboard integration for nvim on remote boxes
    xsel
    xclip
  ];

  # npm i -g needs a writable prefix now that node lives in the read-only
  # nix store (nvm previously pointed npm at per-version directories)
  home.sessionVariables.NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
  home.sessionPath = [ "${config.home.homeDirectory}/.npm-global/bin" ];

  # Dotfile symlinks -- replaces the `configs/` symlink loop in install.sh.
  home.file = {
    ".zshrc".source = link "configs/.zshrc";
    ".zshenv".source = link "configs/.zshenv";
    ".p10k.zsh".source = link "configs/.p10k.zsh";
    ".vimrc".source = link "configs/.vimrc";
    ".tmux.conf".source = link "configs/.tmux.conf";
    ".gitconfig".source = link "configs/.gitconfig";
    ".global-gitignore".source = link "configs/.global-gitignore";
    "personalize".source = link "configs/personalize";
  } // lib.optionalAttrs isDarwin {
    # mac-only tools (the old loop linked these everywhere; scoped here)
    ".skhdrc".source = link "configs/.skhdrc";
    ".aerospace.toml".source = link "configs/.aerospace.toml";
    ".config/ghostty/config".source = link "configs/ghostty/config";
    # lazygit reads from Application Support on macOS
    "Library/Application Support/lazygit/config.yml".source = link "configs/lazygit/config.yml";
  };

  xdg.configFile = {
    "starship.toml".source = link "configs/dotconfig/starship.toml";
    "lsd".source = link "configs/dotconfig/lsd";
  } // lib.optionalAttrs isLinux {
    "lazygit/config.yml".source = link "configs/lazygit/config.yml";
  };
}
