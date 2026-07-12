{
  description = "common dev env";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    codex-cli-nix.url = "github:sadjow/codex-cli-nix";
    claude-code-nix.url = "github:sadjow/claude-code-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      codex-cli-nix,
      claude-code-nix
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import rust-overlay) claude-code-nix.overlays.default ];
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
            "34"
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
          ndkVersions = [
            "27.1.12297006"
            "28.2.13676358"
          ];
          includeExtras = [ "extras;google;auto" ];
          includeSystemImages = true;
        }).androidsdk;

      targetPkgs =
        with pkgs;
        [
          pkg-config
          protobuf
          cmake
          nodejs
          xdotool
          dioxus-cli
          bun
          yarn
          uv
          chromium
          go
          diesel-cli
          dart
          typescript-language-server
          flutter
          clangStdenv.cc

	  claude-code

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
          wayland
          alsa-lib
          udev
          webkitgtk_4_1
          libappindicator-gtk3
          libsecret
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

	  codex-cli-nix.packages.${system}.default
        ];
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = targetPkgs;
        ANDROID_HOME = "${androidComposition}/libexec/android-sdk";
        ANDROID_NDK_ROOT = "${androidComposition}/libexec/android-sdk/ndk-bundle";
        JAVA_HOME = "${pkgs.jdk.home}";
        GOPATH = "~/.gopath";
        shellHook = ''
          fish
        '';
      };
    };
}
