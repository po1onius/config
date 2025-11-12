{
  config,
  lib,
  pkgs,
  sf-fonts,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking = {
    hostName = "nixos";
    wireless.iwd.enable = true;
    nameservers = [ "8.8.8.8" ];
  };

  time.timeZone = "Asia/Shanghai";

  i18n.defaultLocale = "zh_CN.UTF-8";

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = false;
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        fcitx5-rose-pine
      ];
    };
  };

  fonts = {
    packages =
      with pkgs;
      [
        nerd-fonts.fira-code
        lxgw-wenkai
        noto-fonts-color-emoji
      ]
      ++ [
        sf-fonts.packages."${pkgs.stdenv.hostPlatform.system}".sf-mono
      ];
  };

  services = {
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    displayManager.gdm.enable = true;
    dae = {
      enable = true;
      configFile = ./static/config.dae;
    };
  };

  users.users.srus = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "audio"
      "video"
      "input"
      "podman"
    ];
    shell = pkgs.fish;
    packages = with pkgs; [
      google-chrome
      starship
      firefox
      alacritty
      helix
      (vscode.override { commandLineArgs = "--ozone-platform=wayland"; }).fhs
      zed-editor-fhs
      tree
      rofi
      qq
      nixd
      nixfmt
      # grim
      # wl-clipboard
      # slurp
      podman-compose
    ];
  };

  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    git
  ];

  programs = {
    fish.enable = true;
    niri.enable = true;
    waybar.enable = true;
  };

  nixpkgs.overlays = [
    (final: prev: {
      qq = prev.qq.override {
        commandLineArgs = "--ozone-platform=wayland --enable-wayland-ime --wayland-text-input-version=3 --disable-gpu";
      };
    })
  ];

  system.stateVersion = "25.05";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];

  nixpkgs.config.allowUnfree = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

}
