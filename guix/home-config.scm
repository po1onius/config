;; This is a sample Guix Home configuration which can help setup your
;; home directory in the same declarative manner as Guix System.
;; For more information, see the Home Configuration section of the manual.
(define-module (guix-home-config)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services desktop)
  #:use-module (gnu services)
  #:use-module (gnu system shadow))

(define home-config
  (home-environment
    (services
      (list
        ;; Uncomment the shell you wish to use for your user:
        ;(service home-bash-service-type)
        (service home-fish-service-type)
        ;(service home-zsh-service-type)
	(simple-service 'defenv home-environment-variables-service-type
	   ;;proxy
	 `(("https_proxy" . "http://127.0.0.1:7890")
	   ("http_proxy"  . "http://127.0.0.1:7890")


	   ("MOZ_ENABLE_WAYLAND" . "1")

           ;;input method
           ("GTK_IM_MODULE" . "fcitx")
           ("QT_IM_MODULE" . "fcitx")
           ("QT_PLUGIN_PATH" . "${HOME}/.guix-profile/lib/qt5/plugins")
           ("GUIX_GTK3_IM_MODULE_FILE" . "${HOME}/.guix-profile/lib/gtk-3.0/3.0.0/immodules-gtk3.cache")))
	(service home-dbus-service-type)
	))))

        ;(service home-files-service-type
        ; `((".guile" ,%default-dotguile)
        ;   (".Xdefaults" ,%default-xdefaults)))

        ;(service home-xdg-configuration-files-service-type
        ; `(("gdb/gdbinit" ,%default-gdbinit)
        ;   ("nano/nanorc" ,%default-nanorc)))))))

home-config
