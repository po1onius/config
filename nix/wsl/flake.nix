{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    rust-overlay.url = "github:oxalica/rust-overlay";
    codex-cli-nix.url = "github:sadjow/codex-cli-nix";
    claude-code-nix.url = "github:sadjow/claude-code-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-wsl,
      rust-overlay,
      codex-cli-nix,
      claude-code-nix,
      ...
    }:
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              rust-overlay
              claude-code-nix
              codex-cli-nix
              ;
          };
          modules = [
            nixos-wsl.nixosModules.default
            {
              wsl.enable = true;
              wsl.defaultUser = "nixos";
              wsl.wslConf.interop = {
                appendWindowsPath = false;
                enabled = false;
              };

              system.stateVersion = "26.11";
            }

            (
              {
                config,
                pkgs,
                rust-overlay,
                claude-code-nix,
                codex-cli-nix,
                ...
              }:
              {
                nix.settings.experimental-features = [
                  "nix-command"
                  "flakes"
                ];
                nixpkgs.overlays = [
                  claude-code-nix.overlays.default
                  (import rust-overlay)
                ];
                nixpkgs.config.allowUnfree = true;
                environment.sessionVariables = {
                  PKG_CONFIG_PATH = "${pkgs.libpq.dev}/lib/pkgconfig";
                };

                environment.systemPackages =
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
                    diffutils
                    gnumake

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
                    postgresql.lib
                    git
                    neovim
                    wget
                    starship
                    nixd
                    nixfmt
                    ripgrep
                    starship
                    podman-compose
                    claude-code
                    (rust-bin.stable.latest.default.override {
                      extensions = [
                        "rust-src"
                        "rust-analyzer"
                      ];
                      targets = [ "wasm32-unknown-unknown" ];
                    })

                  ]
                  ++ [
                    codex-cli-nix.packages.${system}.default
                  ];

                virtualisation.containers.enable = true;
                virtualisation = {
                  podman = {
                    enable = true;
                    defaultNetwork.settings.dns_enabled = true;
                  };
                };
                programs.fish.enable = true;
                programs.nix-ld.enable = true;

                users.users.nixos = {
                  shell = pkgs.fish;
                };
              }
            )
          ];
        };
      };
    };
}
