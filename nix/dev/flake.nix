{
  description = "rust dev";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
      in
      {
        devShells.default =
          with pkgs;
          mkShell rec {
            buildInputs = [
              cmake
              cmake-language-server
              bear
              dbus
              udev
              alsa-lib-with-plugins
              vulkan-loader
              wayland
              libxkbcommon
              openssl
              pkg-config
              libGL
              lldb
              clang-tools
              (rust-bin.nightly.latest.default.override {
                extensions = [
                  "rust-src"
                  "rust-analyzer"
                ];
              })
            ];
            # LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;
            shellHook = ''
              export PS1='\[\e[35m\][\w]\[\e[0m\]\$ '
            '';
          };
      }
    );
}
