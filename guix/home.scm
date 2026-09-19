(use-modules (gnu home)
             (gnu services)
             ((gnu packages) #:select (specifications->packages))
             (gnu home services shells)
             ((gnu packages shellutils) #:select (starship))
             (gnu home services)
 (gnu home services dotfiles)      ;把 ~/config/dotfile 映射进 $HOME
 (gnu packages fcitx5)
 (gnu home services sound)
 (gnu home services desktop)
             (guix gexp)
             ;; rosenthal channel：图形会话探测 + waybar（状态栏）home 服务
             ((rosenthal home services desktop)
              #:select (home-graphical-session-service-type
                        home-graphical-session-configuration))
             ((rosenthal services desktop)
              #:select (home-waybar-service-type
                        home-fcitx5-service-type
                        home-fcitx5-configuration)))

(home-environment
 (packages
  (specifications->packages
   '(;; Editing, repositories, and terminal sessions.
     "git" "neovim" "openssh" "tmux"
     ;; Interactive shell and prompt.
     "starship" "alacritty" "google-chrome-stable" "font-lxgw-wenkai" "font-apple-sf-mono" "font-awesome" "font-nerd-symbols" "rofi" "firefox"
     ;; 状态栏 waybar（home-waybar 服务默认也用这个包，装进来方便手动调试）
     "waybar"
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
     ;; 输入法相关的包不再手写：fcitx5 / fcitx5-gtk / fcitx5-qt / fcitx5-configtool
     ;; 由 home-fcitx5-service-type 自动加进 profile；中文引擎与主题通过它的
     ;; input-method-editors / themes 字段给出（见下面 services）。
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

       ;;硬件视频解码：iHD 后端 + 显式指定驱动目录。
       ;;Guix 编译 libva 时把 mesa 的 lib/dri 烧进了默认搜索路径
       ;;(gnu/packages/video.scm 的 --with-drivers-path)，而 Intel 驱动不
       ;;在那儿，所以必须覆盖 LIBVA_DRIVERS_PATH 指到 home profile。
       ;;注意变量名带 S；guix home 不会自动展开 profile 的搜索路径。
       ("LIBVA_DRIVER_NAME" . "iHD")))

       ;;input method：XMODIFIERS / QT_IM_MODULE / GTK_IM_MODULE 由
       ;;home-fcitx5-service-type 自己设置（见下面 services），这里只留它不管的两项。
       ;;("QT_PLUGIN_PATH" . "${HOME}/.guix-home/profile/lib/qt6/plugins")
       ;;("GUIX_GTK3_IM_MODULE_FILE" . "${HOME}/.guix-home/profile/lib/gtk-3.0/3.0.0/immodules-gtk3.cache")))
    (service home-pipewire-service-type)
 
    (service home-dbus-service-type)

    ;; ── 状态栏 waybar（来自 rosenthal channel）─────────────────────────
    ;; home-waybar 的 shepherd 服务 requirement 是 (graphical-session)，而这个
    ;; provision 由 home-graphical-session 提供：它会等着 niri 的 Wayland
    ;; socket 出现（默认最多 10 秒，我们这里会话里 shepherd 比 socket 早约 1 秒
    ;; 启动，够用），所以这两个服务必须成对出现，否则 waybar 不会启动。
    ;; waybar 的配置/样式默认取包自带的 etc/xdg/waybar（在 XDG_CONFIG_DIRS
    ;; 里）；想自定义就写 ~/.config/waybar/{config.jsonc,style.css}。
    (service home-graphical-session-service-type)
    (service home-waybar-service-type)

    ;; ── 输入法 fcitx5（同样来自 rosenthal channel）────────────────────
    ;; requirement 是 (dbus graphical-session)：dbus 来自 home-dbus，图形会话
    ;; 来自上面那个服务；它启动【前台】fcitx5（不带 -d）并继承会话环境，
    ;; XMODIFIERS / QT_IM_MODULE / GTK_IM_MODULE 也由它设置 —— 所以 niri 里
    ;; 原来的 spawn-at-startup "fcitx5" "-d" 已删除。没有 respawn，崩了用
    ;; `herd start fcitx5` 拉起。
    (service home-fcitx5-service-type
             (home-fcitx5-configuration
              ;; 中文引擎（拼音等）和主题：服务不会自动加，必须显式给
              (input-method-editors (list fcitx5-chinese-addons))
              (themes (list fcitx5-material-color-theme))))

    ;; ── dotfiles：把 ~/config/dotfile 映射进 $HOME ────────────────────
    ;; layout 'plain 的规则是 <目录>/<相对路径> → ~/<相对路径>，所以 dotfile
    ;; 里保留了 .config/ 这一层（dotfile/.config/niri/config.kdl →
    ;; ~/.config/niri/config.kdl）。source-directory 默认就是本文件所在目录，
    ;; 所以这里写 ../dotfile。默认已排除 *~  *.swp  .git/  .gitignore。
    ;; 注意：目标会变成指向 /gnu/store 的【只读】符号链接 —— 以后改配置要改
    ;; ~/config/dotfile/... 再 `guix home reconfigure`；挡路的旧文件会被自动
    ;; 备份到 ~/<时间戳>-guix-home-legacy-configs-backup/。
    (service home-dotfiles-service-type
             (home-dotfiles-configuration
              (directories '("../dotfile"))
              (layout 'plain)))

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
