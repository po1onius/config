{ config, lib, pkgs, ... }:

{
  imports =
    [
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
      addons = with pkgs; [ fcitx5-chinese-addons fcitx5-rose-pine ];
    };
  };


  fonts = {
    packages = with pkgs; [
      intel-one-mono
      nerd-fonts.fira-code      
      wqy_microhei
      noto-fonts-emoji
      twemoji-color-font
    ];
  };
    
  services = {
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    v2raya.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "sddm-astronaut-theme";
      extraPackages = [ pkgs.sddm-astronaut ];
      package = pkgs.kdePackages.sddm;
    };
  };


  users.users.srus = {
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "video" "input"];
    shell = pkgs.fish;
    packages = with pkgs; [
      google-chrome
      alacritty
      helix
      # zed-editor
      tree
      rofi-wayland
      qq
      # grim
      # wl-clipboard
      # slurp
    ];
  };

  environment.systemPackages = with pkgs; [
    wget
    git
    sddm-astronaut
  ];

  programs = {
    niri.enable = true;
    waybar.enable = true;
    fish.enable = true;
  };

  nixpkgs.overlays = [
   (final: prev: {
     qq = prev.qq.override {
       commandLineArgs = "--ozone-platform=wayland";
     };
   })
  #  (final: prev: {
  #    wemeet = prev.wemeet.overrideAttrs (oldAttrs: {
  #      postInstall = ''
  #        sed -i 's/Exec=wemeet %u/Exec=wemeet-xwayland %u/' $out/share/applications/wemeetapp.desktop
  #      '';
  #    });
  #  })
  ];

  system.stateVersion = "24.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

}

