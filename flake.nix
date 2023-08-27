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
      let pkgs = nixpkgs.legacyPackages.${system};
      in with pkgs; {
        devShells.default = mkShell {
          buildInputs = [
            haskell-language-server
            (haskellPackages.ghcWithPackages
              (pkgs: with pkgs; [ shake mustache ]))
          ];
        };
      });
}
