{
  description = "The arx tool, bundle code for execution";
  inputs.haskellNix.url = "github:input-output-hk/haskell.nix";
  inputs.nixpkgs.follows = "haskellNix/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils, haskellNix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
    let
      overlays = [ haskellNix.overlay
        (final: prev: {
          # This overlay adds our project to pkgs
          arxProject =
            final.haskell-nix.project' {
              src = ./.;
              compiler-nix-name = "ghc967";
              # This is used by `nix develop .` to open a shell for use with
              # `cabal`, `hlint` and `haskell-language-server`
              shell.tools = {
                cabal = {};
                hlint = {};
                haskell-language-server = {};
              };
              # Non-Haskell shell tools go here
              shell.buildInputs = with pkgs; [
                #nixpkgs-fmt
              ];
              # This adds `js-unknown-ghcjs-cabal` to the shell.
              # shell.crossPlatforms = p: [p.ghcjs];
            };
        })
      ];
      pkgs = import nixpkgs { inherit system overlays; inherit (haskellNix) config; };
      flake = pkgs.arxProject.flake {
        # This adds support for `nix build .#js-unknown-ghcjs:hello:exe:hello`
        crossPlatforms = p: if (system == "x86_64-linux") then [p.musl64] else [];
      };
    in pkgs.lib.recursiveUpdate flake {
      # Built by `nix build .`
      packages.default = flake.packages."arx:exe:arx";
    });
}
