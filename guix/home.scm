(use-modules (gnu home)
             (gnu services)
             ((gnu packages) #:select (specifications->packages))
             (gnu home services shells)
             ((gnu packages shellutils) #:select (starship))
             (gnu home services)
 (gnu packages fcitx5)
 (gnu home services sound)
 (gnu home services desktop)
             (guix gexp))

(home-environment
 (packages
  (specifications->packages
   '(;; Editing, repositories, and terminal sessions.
     "git" "neovim" "openssh" "tmux"
     ;; Interactive shell and prompt.
     "starship" "alacritty" "google-chrome-stable" "font-lxgw-wenkai" "font-apple-sf-mono" "rofi" "firefox"
     ;; Codex from the configured channel, including its runtime helpers.
     "bubblewrap" "codex-bin"
     ;; Searching, inspecting files, and working with APIs.
     "ripgrep" "fd" "jq" "curl" "file" "tree"
     ;; Python project management, JavaScript runtime, and shell checks.
     "uv" "node" "shellcheck"
     ;; C/C++ builds and native Python/Node.js dependencies.
     "gcc-toolchain@14" "make" "pkg-config" "cmake" "ninja"
     ;; Archive formats not already provided by the base system.
     "zip" "unzip"
     ;; Hardware video decoding: the VA-API backend for the Intel iGPU
     ;; (Mesa does NOT ship an Intel VA driver), plus vainfo to check it.
     "intel-media-driver" "libva-utils"
    "fcitx5"
    "fcitx5-qt"
    "fcitx5-gtk"
    "fcitx5-gtk4"
    "fcitx5-configtool"
    "fcitx5-chinese-addons"
    "fcitx5-material-color-theme"
 )))
 (services
  (list 
    (simple-service
     'defenv home-environment-variables-service-type
     ;;proxy
     ;`(("https_proxy" . "http://127.0.0.1:7890")
     ;  ("http_proxy"  . "http://127.0.0.1:7890")
     ;  ("HTTP_PROXY"  . "http://127.0.0.1:7890")
     ;  ("HTTPS_PROXY"  . "http://127.0.0.1:7890")


      `(("MOZ_ENABLE_WAYLAND" . "1")

       ;;硬件视频解码：Arrow Lake 核显要用 iHD 这个 VA-API 后端
       ("LIBVA_DRIVER_NAME" . "iHD")

       ;;input method
       ("GTK_IM_MODULE" . "fcitx")
       ("QT_IM_MODULE" . "fcitx")
       ("QT_PLUGIN_PATH" . "${HOME}/.guix-home/profile/lib/qt6/plugins")
       ("GUIX_GTK3_IM_MODULE_FILE" . "${HOME}/.guix-home/profile/lib/gtk-3.0/3.0.0/immodules-gtk3.cache")))
    (service home-pipewire-service-type)
 
    (service home-dbus-service-type)
   (service home-fish-service-type
            (home-fish-configuration
             (config
              (list
               (mixed-text-file
                "fish-starship.fish"
                "if status is-interactive\n"
                "    " (file-append starship "/bin/starship")
                " init fish | source\n"
                "end\n"))))))))
