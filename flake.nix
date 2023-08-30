{
  description = "Dev shell flake for plugin-scaffold";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };
  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        plugin-scaffold = pkgs.haskellPackages.callPackage ./nix { };
      in with pkgs; {
        devShells.default = (haskell.lib.addBuildTools plugin-scaffold [
          haskell-language-server
          cabal2nix
          cabal-install
        ]).envFunc { };
        packages.default = haskell.lib.justStaticExecutables plugin-scaffold;
      });
}
