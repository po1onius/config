;; This is a sample Guix Home configuration which can help setup your
;; home directory in the same declarative manner as Guix System.
;; For more information, see the Home Configuration section of the manual.
(use-modules
 (gnu home)
 (gnu home services)
 (gnu home services sound)
 (gnu packages)
 (gnu packages wm)
 (gnu packages image)
 (gnu packages ssh)
 (gnu packages qt)
 (gnu packages fcitx5)
 (gnu packages gtk)
 (gnu packages terminals)
 (gnu packages video)
 (gnu packages linux)
 (gnu packages xdisorg)
 (gnu packages text-editors)
 (gnu packages containers)
 (gnu packages freedesktop)
 (gnu packages fonts)
 (gnu packages version-control)
 (gnu packages package-management)
 (gnu home services shells)
 (gnu home services desktop)
 (gnu home services shepherd)
 (nongnu packages chrome)
 (nongnu packages fonts)
 (ch0r0ng packages wm)
 (gnu services)
 (gnu system shadow)
 (guix inferior)
 (guix channels)
 (srfi srfi-1)
 (ch0r0ng services network))


(define channel-rust-team
  (list (channel
         (name 'guix)
         (url "https://codeberg.org/guix/guix.git")
         (branch "rust-team")
	     (introduction
	      (make-channel-introduction
	       "9edb3f66fd807b096b48283debdcddccfea34bad"
	       (openpgp-fingerprint
	        "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))))


(define inferior-rust-team
  (inferior-for-channels channel-rust-team))


(home-environment
 (packages
  (append
   (list
	openssh
	flatpak
	obs
	obs-wlrobs
	sway
	mango-git
	hyprland
	slurp
	wl-clipboard
	grim
	gtk+
	waybar-git
	fcitx5
	fcitx5-qt
	fcitx5-gtk
	fcitx5-gtk4
	fcitx5-configtool
	fcitx5-chinese-addons
	fcitx5-material-color-theme
	alacritty
	rofi-wayland
	google-chrome-stable
	git
	bluez
	podman-compose
	font-google-noto-emoji
	font-awesome-nonfree
	font-apple-sf-mono
	font-lxgw-wenkai-tc
	qtwayland)
   (map 
	(lambda (packs) 
	  (first (lookup-inferior-packages inferior-rust-team packs)))
	'("helix" "niri" "starship"))))

 
 (services
  (append
   (list
    (service home-fish-service-type)
    (simple-service
     'defenv home-environment-variables-service-type
     ;;proxy
     `(("https_proxy" . "http://127.0.0.1:7890")
       ("http_proxy"  . "http://127.0.0.1:7890")


       ("MOZ_ENABLE_WAYLAND" . "1")

       ;;input method
       ("GTK_IM_MODULE" . "fcitx")
       ("QT_IM_MODULE" . "fcitx")
       ("QT_PLUGIN_PATH" . "${HOME}/.guix-home/profile/lib/qt6/plugins")
       ("GUIX_GTK3_IM_MODULE_FILE" . "${HOME}/.guix-home/profile/lib/gtk-3.0/3.0.0/immodules-gtk3.cache")))
    (service home-clash-service-type)
    (service home-pipewire-service-type)
    (service home-dbus-service-type))
   %base-home-services)
  ))

