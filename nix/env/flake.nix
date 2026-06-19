{
  description = "common dev env";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      llm-agents,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import rust-overlay) ];
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };

      rustToolchain = pkgs.rust-bin.stable.latest.default.override {
        extensions = [
          "rust-src"
          "rust-analyzer"
        ];
        targets = [ "wasm32-unknown-unknown" ];
      };

      androidComposition =
        (pkgs.androidenv.composeAndroidPackages {
          platformVersions = [
            "36"
            "35"
            "latest"
          ];
          buildToolsVersions = [
            "35.0.0"
            "36.0.0"
            "latest"
          ];
          systemImageTypes = [ "google_apis" ];
          abiVersions = [
            "armeabi-v7a"
            "arm64-v8a"
            "x86_64"
          ];
          includeEmulator = true;
          cmakeVersions = [
            "3.22.1"
          ];
          includeNDK = true;
          ndkVersion = "27.1.12297006";
          includeExtras = [ "extras;google;auto" ];
          includeSystemImages = true;
        }).androidsdk;

      targetPkgs =
        with pkgs;
        [
          pkg-config
          protobuf
          gcc
          cmake
          nodejs
          xdotool
          dioxus-cli
          clang-tools
          llvmPackages.clang-unwrapped
          bun
          yarn
          uv
          chromium
          go
          libc
          diesel-cli
          dart
          typescript-language-server
          flutter
          pkgs.stdenv.cc.cc.lib
          glibc.dev

          linuxHeaders
          sqlite
          elfutils
          openssl
          libbpf
          zlib
          libXi
          libX11
          libXtst
          xorgproto
          libxcb
          libxcursor
          libinput
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
          fontconfig
          postgresql
        ]
        ++ [
          rustToolchain
          androidComposition
        ]
        ++ (with llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
          codex
          claude-code
        ]);
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = targetPkgs;
        shellHook = ''
          export PKG_CONFIG_PATH=/usr/share/pkgconfig:/usr/lib/pkgconfig
          export ANDROID_HOME=${androidComposition}/libexec/android-sdk
          export ANDROID_NDK_ROOT=${androidComposition}/libexec/android-sdk/ndk-bundle
          export JAVA_HOME=${pkgs.jdk.home}
          export GOPATH=~/.gopath
          fish
        '';
      };
    };
}
