{
  description = "ayu's dotfiles -- home-manager flake for CLI packages, toolchains, and config symlinks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      # Username/home are read from the environment so the same flake works
      # across machines with different usernames (mac, personal servers, work
      # devboxes). Requires `--impure`, which dependencies/nix-and-home-manager.sh
      # always passes.
      username =
        let u = builtins.getEnv "USER";
        in if u == "" then "ayu" else u;

      mkHome = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          defaultHome =
            if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
          homeDirectory =
            let h = builtins.getEnv "HOME";
            in if h == "" then defaultHome else h;
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./nix/home.nix
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
            }
          ];
        };
    in
    {
      # Keyed by system so the bootstrap script can pick via uname:
      #   home-manager switch --flake ~/dotfiles#x86_64-linux --impure
      homeConfigurations = nixpkgs.lib.genAttrs systems mkHome;
    };
}
