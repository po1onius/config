;; This is a sample Guix Home configuration which can help setup your
;; home directory in the same declarative manner as Guix System.
;; For more information, see the Home Configuration section of the manual.
(use-modules (gnu home)
	     (gnu home services)
	     (gnu home services sound)
	     (gnu packages wm)
	     (gnu packages image)
	     (gnu packages ssh)
	     (gnu packages fcitx5)
	     (gnu packages gtk)
	     (gnu packages terminals)
	     (gnu packages linux)
	     (gnu packages xdisorg)
	     (gnu packages text-editors)
	     (gnu packages freedesktop)
	     (gnu packages fonts)
	     (gnu packages version-control)
	     (gnu services configuration)
	     (gnu home services shells)
	     (gnu home services desktop)
	     (gnu home services shepherd)
	     (guix gexp)
	     (guix records)
	     (nongnu packages chrome)
	     (nongnu packages fonts)
	     (gnu services)
	     (gnu system shadow)
	     (rosenthal packages binaries))


(define-configuration clash-configuration
  (clash
   (file-like mihomo-bin)
   "The clash package.")


  (config-path
   (string ".config/clash")
   "config path")
  (no-serialization))

(define clash-shepherd-service
  (match-record-lambda
   <clash-configuration>
   (clash config-path)
   (list
    (shepherd-service
     (documentation "Run clash.")
     (provision (list 'clash))
     (start
      #~(make-forkexec-constructor
	 (list
	  (let ((mihomo-cmd
		 #$(file-append clash "/bin/mihomo"))
		(clash-cmd
		 #$(file-append clash "/bin/clash")))
	    (if (file-exists? mihomo-cmd)
		mihomo-cmd
		clash-cmd))
	  "-d" #$config-path)))
     (stop #~(make-kill-destructor))))))

(define clash-service-type
  (service-type
   (name 'clash)
   (extensions
    (list (service-extension
	   home-shepherd-service-type
	   clash-shepherd-service)))
   (description "clash service")
   (default-value (clash-configuration))))

(home-environment
 (packages (list
	    openssh
	    sway
	    slurp
	    wl-clipboard
	    grim
	    gtk+
	    waybar
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
	    helix
	    bluez
	    font-google-noto-emoji
	    font-awesome-nonfree
	    font-apple-sf-mono
	    font-lxgw-wenkai-tc))
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
       ("QT_PLUGIN_PATH" . "${HOME}/.guix-profile/lib/qt5/plugins")
       ("GUIX_GTK3_IM_MODULE_FILE" . "${HOME}/.guix-profile/lib/gtk-3.0/3.0.0/immodules-gtk3.cache")))
    (service clash-service-type)
    (service home-pipewire-service-type)
    (service home-dbus-service-type))
   %base-home-services)
  ))

