(use-modules
 (gnu)
 (gnu packages shells)
 (gnu packages linux)
 (gnu packages window-management)
 (gnu packages version-control)
 (gnu packages fonts)              ;中文字体（SDDM 登录界面也要用）
 (gnu packages qt)                 ;qtmultimedia（astronaut 主题需要）
 (gnu packages display-managers)   ;Qt6 版 sddm 包（默认的 sddm-qt5 是 Qt5 版）
 (nongnu packages linux)
 (nongnu system linux-initrd)
 (gnu services networking)
 (gnu services desktop)
 (gnu services sound)
 (gnu services dbus)
 (gnu services containers)
 (gnu services xorg)
 (gnu services sddm)               ;SDDM 登录管理器
 (ch0r0ng services networking)
 (ch0r0ng services clash-verge)
 (ch0r0ng packages sddm-astronaut-theme)  ;本地 channel 里的 SDDM 主题
 (ch0r0ng packages wm)                    ;niri-shm-sharing（带 SHM 采集回退的 niri）
 (gnu system accounts)
 (gnu services base)               ;%default-authorized-guix-keys
 (gnu build file-systems)          ;find-partition-by-label、read-partition-uuid
 (gnu system uuid)                 ;bytevector->uuid
 (ice-9 format)
 )

;; 本机分区固定用这两个文件系统标签：
;;   ROOT —— 根文件系统（ext4）
;;   BOOT —— EFI 系统分区（FAT32）
;; 这份配置不写死 UUID，也不依赖 /dev/nvme0n1pX 这样的设备名，而是在求值时
;; 自己去盘上找这两个标签、读出它们的 UUID。
;;
;; 标签用 mkfs 打上即可，例如：
;;   mkfs.ext4 -L ROOT /dev/xxx2
;;   mkfs.fat -F 32 -n BOOT /dev/xxx1
;;
;; 注意：读超级块需要 root 权限，设备节点也必须已经存在（udev 就绪），
;; 所以请在正在运行的目标系统上以 root 求值，例如：
;;   sudo guix system reconfigure ~/config/guix/system.scm

(define %boot-label "GX_BOOT")
(define %root-label "GX_ROOT")

;; ── 用户相关的信息只在这里维护 ─────────────────────────────────────────
;; 用户名 / 家目录 / 主组 / 附加组。"cgroup" 是 rootless podman 必需的：
;; rootless-podman 服务会把 /sys/fs/cgroup 的属主设为 root:cgroup。
(define %user-name "liz")
(define %user-home (string-append "/home/" %user-name))
(define %user-group "users")
(define %user-supplementary-groups
  '("wheel" "netdev" "audio" "video" "input" "clash-verge" "cgroup"))

(define (uuid-by-label label type)
  "在磁盘上找文件系统标签为 LABEL 的分区，返回它带类型 TYPE 的 UUID 对象；
找不到、或者类型不符（DCE UUID 16 字节、FAT UUID 4 字节）就直接报错。"
  (define (fail fmt . args)
    (error (format #f "找不到标签为 ~s 的 ~a 文件系统：~a"
                   label type (apply format #f fmt args))))

  (let ((partition (find-partition-by-label label)))
    (unless partition
      (fail "磁盘上没有任何分区带这个标签"))
    (let ((bv (false-if-exception (read-partition-uuid partition))))
      (unless bv
        (fail "~a 读不出文件系统 UUID（需要 root 权限，或设备节点不存在）"
              partition))
      (let ((expected (if (memq type '(fat fat16 fat32 exfat)) 4 16)))
        (unless (= (u8vector-length bv) expected)
          (fail "~a 的 UUID 是 ~a 字节，与 ~a 应有的 ~a 字节不符"
                partition (u8vector-length bv) type expected))
        (bytevector->uuid bv type)))))

(operating-system
 (kernel linux-7.2)
 (firmware (list linux-firmware))
 (initrd microcode-initrd)
 (locale "zh_CN.utf8")
 (timezone "Asia/Shanghai")
 (keyboard-layout (keyboard-layout "us"))
 (host-name "guix-PC")

 (users
  (cons
   (user-account
    (name %user-name)
    (comment %user-name)
    (shell (file-append fish "/bin/fish"))
    (group %user-group)
    (home-directory %user-home)
    (supplementary-groups %user-supplementary-groups))
   %base-user-accounts))

 ;; font-lxgw-wenkai（霞鹜文楷）：装进【系统】profile 才能被登录管理器看到。
 ;; SDDM 的 greeter 以 XDG_DATA_DIRS=/run/current-system/profile/share 启动，
 ;; fontconfig 会扫 $XDG_DATA_DIRS/*/fonts；系统 profile 里没有中文字体时只能
 ;; 退回 fontconfig 自带的 DejaVu，中文就显示成方块。
 ;; niri-git = 直接跟 niri main 编译（见 ch0r0ng/packages/wm.scm）。
 ;; SHM 采集回退（上游 PR #1791）已合并进主线但还没有 release（最新 release 仍是
 ;; 26.04），所以 Guix 里的 niri 还没有它。厂商腾讯会议请求 PipeWire 采集流时不指定
 ;; VideoModifier，而 PipeWire 的约定是"没有 VideoModifier ⇒ 只能用共享内存缓冲"：
 ;; 原版 niri 只 offer DMA-BUF，协商直接失败；强行走线性 dmabuf 又会在 Intel Gen12 上
 ;; 静默出黑帧（niri issue #4123）。main 会在这种情况下 offer MemFd，共享屏幕才出画面。
 ;; 包名/bin/niri/niri.desktop 与 niri 一致，登录菜单里就是它。
 (packages (cons* niri-git git font-lxgw-wenkai
                  sddm-astronaut-theme   ;SDDM 主题（Qt6，10 套预设）
                  qtmultimedia           ;必需：Main.qml 顶部无条件 import QtMultimedia
                  %base-packages))

 (services
  (append
   (list
    ;; 登录管理器：SDDM（Qt greeter，自带默认主题与 Qt 插件，不依赖 GNOME 的
    ;; GSettings schema，也不需要 GDM 那套 gdm-file-system-service）。
    ;; 它自己 provision xorg-server/display-manager，会话目录默认就是
    ;; /run/current-system/profile/share/{wayland-sessions,xsessions}，
    ;; 所以 niri 会直接出现在登录界面的会话菜单里。
    (service sddm-service-type
             (sddm-configuration
              (sddm sddm)                      ;★ Qt6 版 greeter（主题 QtVersion=6）
              (theme "sddm-astronaut-theme")))
    ;; 下面几个是通用桌面件（%desktop-services 里也有），SDDM 用得到、留着无妨：
    ;;   x11-socket-directory —— 保证 /tmp/.X11-unix 存在（X11 客户端/XWayland）。
    ;;   accountsservice      —— 登录界面列用户、记住上次会话。
    ;;   upower               —— 桌面电源管理。
    (service x11-socket-directory-service-type)
    (service accountsservice-service-type)
    (service upower-service-type)
    (service elogind-service-type
             (elogind-configuration
              (handle-power-key 'ignore)))
    (service bluetooth-service-type)
    (service iwd-service-type)
    (service dhcpcd-service-type)

    ;; ── Podman（rootless，来自 (gnu services containers)）─────────────
    ;; rootless-podman-service-type 会：把 podman 装进系统 profile；写
    ;; /etc/containers/{registries,storage,policy}.conf；给 %user-name 分配
    ;; subuid/subgid；把 /sys/fs/cgroup 属主设为 root:cgroup（见上面用户的
    ;; cgroup 组）；并放开 cgroup v2 的 cpu/cpuset/io/memory/pids 控制器。
    ;; podman 6.x 的 netavark/aardvark-dns/crun/conmon/passt 已由 podman 包
    ;; 的 PATH 包装提供；按 Guix 手册，iptables-service-type 也是 podman 自己
    ;; 配置网络所必需的。改完要重新登录（组变更才生效）。
    (service iptables-service-type)
    (service rootless-podman-service-type
             (rootless-podman-configuration
              (subuids (list (subid-range (name %user-name))))
              (subgids (list (subid-range (name %user-name))))))
    (service clash-verge-service-type
                  (clash-verge-configuration
                   (install-gui? #t)
                   (tun-mode? #t)))

   (service polkit-service-type)
   )
   (modify-services
    %base-services
    (guix-service-type
     config =>
     (guix-configuration
      (inherit config)
      (privileged? #f)
      (substitute-urls
       '("https://mirror.sjtu.edu.cn/guix"
         "https://mirror.sjtu.edu.cn/guix-bordeaux"
         "https://ci.guix.moe"
         "https://ci.guix.gnu.org"
         "https://bordeaux.guix.gnu.org"))
      ;; ci.guix.moe 上的 nonguix jobset 提供 firefox 等 nonguix 包的预构建
      ;; 替代品，但它用自己的一把 Ed25519 签名公钥（nuporta）。官方 CI 不
      ;; 构建 nonguix，所以不授权这把钥匙就永远只能本地编译 firefox。
      (authorized-keys
       (cons (local-file "nonguix-ci.guix.moe.pub")
             %default-authorized-guix-keys))
      )))))

 (bootloader
  (bootloader-configuration
   (bootloader grub-efi-bootloader)
   (targets (list "/boot/efi"))
   (keyboard-layout keyboard-layout)))

 (file-systems
  (append
   (list
    (file-system
     (mount-point "/boot/efi")
     ;; ESP：按固定标签 BOOT 找
     (device (uuid-by-label %boot-label 'fat32))
     (type "vfat"))
    (file-system
     (mount-point "/")
     ;; 根文件系统：按固定标签 ROOT 找
     (device (uuid-by-label %root-label 'ext4))
     (type "ext4"))) %base-file-systems)))
