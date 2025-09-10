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
    proxy.default = "http://127.0.0.1:7890";
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
        fcitx5-chinese-addons
        fcitx5-rose-pine
      ];
    };
  };

  fonts = {
    packages =
      with pkgs;
      [
        intel-one-mono
        nerd-fonts.fira-code
        lxgw-wenkai
        noto-fonts-emoji
      ]
      ++ [
        sf-fonts.packages."${pkgs.system}".sf-mono
      ];
  };

  services = {
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    v2raya.enable = true;
    displayManager.gdm.enable = true;
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
      alacritty
      helix
      zed-editor
      vscode-fhs
      tree
      rofi-wayland
      qq
      nixd
      nixfmt-rfc-style
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
  nixpkgs.config.allowUnfree = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

}
