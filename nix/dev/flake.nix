{
  description = "rust dev";

  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
      in
      {
        devShells.default = with pkgs; mkShell rec {
          buildInputs = [
            udev
            alsa-lib-with-plugins
            vulkan-loader
            wayland
            libxkbcommon
            openssl
            pkg-config
            libGL
            (rust-bin.stable.latest.default.override {
              extensions = [ "rust-src" "rust-analyzer" ];
            })
          ];
          LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;
          shellHook = ''
            export PS1='\[\e[35m\][\w]\[\e[0m\]\$ '
          '';
        };
      }
    );
}
