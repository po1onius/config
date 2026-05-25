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
    # wireless.iwd.enable = true;
    nameservers = [ "8.8.8.8" ];
    firewall = {
      enable = false;
    };
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
    desktopManager.gnome.enable = true;
    gnome.core-developer-tools.enable = false;
    gnome.games.enable = false;
  };

  users.users.srus = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "audio"
      "video"
      "input"
      "podman"
      "render"
    ];
    shell = pkgs.fish;
    packages = with pkgs; [
      #google-chrome
      starship
      firefox
      ghostty
      neovim
      tree
      (qq.override {
        commandLineArgs = "--ozone-platform=wayland --enable-wayland-ime --wayland-text-input-version=3 --enable-features=WaylandWindowDecorations";
      })
      nixd
      nixfmt
      podman-compose
      pax-utils
    ];
  };

  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      ripgrep
      wget
      git
      gnomeExtensions.appindicator
      gnomeExtensions.system-monitor-next
    ];
    sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };
    gnome.excludePackages = [
      pkgs.baobab
      pkgs.decibels
      pkgs.epiphany
      pkgs.gnome-text-editor
      pkgs.gnome-calculator
      pkgs.gnome-calendar
      pkgs.gnome-characters
      pkgs.gnome-clocks
      pkgs.gnome-console
      pkgs.gnome-contacts
      pkgs.gnome-font-viewer
      pkgs.gnome-logs
      pkgs.gnome-maps
      pkgs.gnome-music
      pkgs.gnome-system-monitor
      pkgs.gnome-weather
      pkgs.loupe
      pkgs.papers
      pkgs.gnome-connections
      pkgs.showtime
      pkgs.simple-scan
      pkgs.snapshot
      pkgs.yelp
    ];
  };

  programs = {
    fish.enable = true;
    #mangowc.enable = true;
    #niri.enable = true;
    #waybar.enable = true;
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-pipewire-audio-capture
        obs-gstreamer
        obs-vkcapture
      ];
    };
    clash-verge = {
      enable = true;
      tunMode = true;
      serviceMode = true;
      autoStart = true;
    };
  };

  system.stateVersion = "25.11";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.substituters = [
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
  ];

  nixpkgs.config.allowUnfree = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
    ];
  };
}
