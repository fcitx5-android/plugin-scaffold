{
  description = "Dev shell flake for fcitx5-android plugin";

  inputs.fcitx5-android.url = "github:fcitx5-android/fcitx5-android";
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, fcitx5-android, ... }:
    fcitx5-android.inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        nixpkgs = fcitx5-android.inputs.nixpkgs;
        pkgs = import nixpkgs {
          inherit system;
          config.android_sdk.accept_license = true;
          config.allowUnfree = true;
          overlays = [ fcitx5-android.overlays.default ];
        };
        # disable ndk
        sdk = pkgs.fcitx5-android.sdk.extend (_: _: { includeNDK = false; });
      in {
        devShells = {
          default = sdk.shell;
          noAS = sdk.shell.override {
            androidStudio = null;
            generateLocalProperties = false;
          };
        };
      });
}
