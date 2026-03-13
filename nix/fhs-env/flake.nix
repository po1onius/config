{
  description = "common dev env";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      android-nixpkgs,
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
        targets = [ "wasm32-unknown-unknown" ];
      };

      vscode = pkgs.vscode.override {
        commandLineArgs = "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true --wayland-text-input-version=3";
      };

      android-sdk = android-nixpkgs.sdk.x86_64-linux (sdkPkgs: with sdkPkgs; [
        cmdline-tools-latest
        build-tools-34-0-0
        platform-tools
        platforms-android-34
        ndk-27-1-12297006
        emulator
      ]);

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
              xdotool
              dioxus-cli
              clang-tools
              llvmPackages.clang-unwrapped
              bun
              android-sdk
              android-studio
              uv

              linuxHeaders
              sqlite
              elfutils              
              openssl
              libbpf
              zlib
              xorg.libXi
              xorg.libX11
              xorg.libXtst
              xorg.xorgproto
              xorg.libxcb
              libxcursor
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
              webkitgtk_4_1
              libappindicator-gtk3
              librsvg
              glib
              libsoup_3
              gtk4
              gtk3
              pango
              cairo
              atk
              gdk-pixbuf
              harfbuzz
              file
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
          export ANDROID_HOME=${android-sdk}/share/android-sdk
          export ANDROID_SDK_ROOT=${android-sdk}/share/android-sdk
          export JAVA_HOME=${pkgs.jdk.home}
        '';
      };      
    in
    {
      devShells.${system}.default = fhs.env;
    };
}
