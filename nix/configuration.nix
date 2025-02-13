{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos";
  networking.wireless.iwd.enable = true;

  time.timeZone = "Asia/Shanghai";

  networking.proxy.default = "http://127.0.0.1:7890";

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
  };

  users.users.srus = {
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "video" "input"];
    packages = with pkgs; [
      google-chrome
      alacritty
      helix
      tree
      rofi-wayland
      qq
      grim
      wl-clipboard
      slurp
    ];
  };

  environment.systemPackages = with pkgs; [
    wget
    git
  ];

  programs = {
    sway = {
      enable = true;
      extraPackages = [];
    };
    waybar.enable = true;
  };
  
  system.stateVersion = "24.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

}

