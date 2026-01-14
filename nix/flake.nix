{
  description = "common dev env";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import rust-overlay) ];
        config.allowUnfree = true;
      };

      rustToolchain = pkgs.rust-bin.nightly.latest.default.override {
        extensions = [
          "rust-src"
          "rust-analyzer"
        ];
      };

      vscode = pkgs.vscode.override {
        commandLineArgs = "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true --wayland-text-input-version=3";
      };

      fhs = pkgs.buildFHSEnv {
        name = "fhs-shell";

        targetPkgs =
          pkgs:
          (
            with pkgs;
            [
              pkg-config
              protobuf
              cmake
              gcc
              nodejs

              openssl
              zlib
              xorg.libXi
              xorg.libX11
              xorg.libXtst
              xorg.xorgproto
              xorg.libxcb
              libinput
              vulkan-loader
              libgbm
              pipewire
              libGL
              libxkbcommon
              libclang
              wayland
              alsa-lib
              udev
            ]
            ++ [
              vscode
              rustToolchain
            ]
          );

        extraOutputsToInstall = [
          "out"
          "dev"
          "lib"
        ];

        profile = ''
          export PKG_CONFIG_PATH=/usr/share/pkgconfig:/usr/lib/pkgconfig
        '';
      };
    in
    {
      devShells.${system}.default = fhs.env;
    };
}
