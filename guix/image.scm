(use-modules
 (gnu)
 (gnu packages shells)
 (gnu packages linux)
 (gnu packages fonts)
 (gnu packages version-control)
 (nongnu packages linux)
 (nongnu system linux-initrd)
 (gnu services networking)
 (gnu services desktop)
 (gnu services sound)
 (gnu services dbus)
 (gnu services xorg)
 (gnu services containers)
 (gnu system install)
 (ch0r0ng services networking)
 (ch0r0ng packages codex)
 (gnu system accounts)
 (guix channels))

;; Start from Guix's official live installation image configuration.
;; This provides the live root file system, the installation initrd
;; modules, and a hybrid BIOS/UEFI GRUB configuration.
(define base-installation-os
  (make-installation-os #:efi-only? #f))

;; Build the live system on top of %desktop-services rather than
;; %base-services.  GNOME cannot come up on %base-services alone: it also
;; needs GDM (the display manager), D-Bus, Polkit, elogind, UPower,
;; AccountsService, NetworkManager and the sound services, and those are
;; only part of the desktop service set.  The GNOME desktop service itself
;; adds GNOME Shell and its applications to the system profile.
(define base-installation-services
  (cons (service gnome-desktop-service-type)
        %desktop-services))

(operating-system
 (inherit base-installation-os)

 (kernel linux-7.2)
 (firmware (list linux-firmware))
 (locale "zh_CN.utf8")
 (timezone "Asia/Shanghai")
 (keyboard-layout (keyboard-layout "us"))
 (host-name "guix-PC")

 ;; The installer blacklists the Radeon and AMDGPU KMS drivers because they
 ;; break its text console (kmscon).  A graphical image needs them, so drop
 ;; the blacklist inherited from 'base-installation-os'.
 (kernel-arguments '("quiet"))

 ;; 'base-installation-os' 把 setuid 程序削减到只剩 passwd（安装器不需要
 ;; 其它特权程序），继承过来会导致镜像里的 sudo 没有 setuid 位、普通用户
 ;; 完全无法使用。live 桌面镜像恢复 Guix 的标准集合，即 sudo、sudoedit、
 ;; su、mount/umount、fusermount 以及 ping 的 capability。
 ;; 密码方面：srus 是空密码，且安装镜像的 pam-services 带
 ;; #:allow-empty-passwords? #t，所以 sudo 直接回车即可。
 (privileged-programs %default-privileged-programs)

 (users
  (cons
   (user-account
    (name "srus")
    (comment "srus")
    ;; password 字段默认值是 #f，会被写成 /etc/shadow 里的 "!"，即锁定
    ;; 账户，GDM 登录界面根本无法登录。live 镜像要显式给空密码。
    (password "")
    (shell (file-append fish "/bin/fish"))
    (group "users")
    (home-directory "/home/srus")
    (supplementary-groups '("wheel" "netdev" "audio" "video"
                            "input")))
   %base-user-accounts))

 (packages
  (append
   (list git
         ;; The GNOME fonts do not cover CJK, so without this the Chinese
         ;; (zh_CN) interface renders as empty boxes.
         font-wqy-zenhei
         ;; Prebuilt OpenAI Codex CLI, from the 'chorong' channel.
         codex-bin)
   (operating-system-packages base-installation-os)))

 (services
  (modify-services
    base-installation-services

    ;; Log straight into the live GNOME session.  The "srus" account on this
    ;; image has an empty password; drop this clause if you would rather get
    ;; the GDM login screen instead.
    (gdm-service-type
     config =>
     (gdm-configuration
      (inherit config)
      (auto-login? #t)
      (default-user "srus")))

    (guix-service-type
     config =>
     (guix-configuration
      (inherit config)
      ;; 必须是 #t（这也是默认值，官方安装镜像就用它）。iso9660 镜像的根
      ;; 文件系统被强制成 volatile-root（gnu/system/image.scm:990），即
      ;; overlayfs（只读 ISO + tmpfs 上层）。而 privileged? #f 会让
      ;; 'guix-ownership' 去 chown -R 整个 /gnu/store 给 guix-daemon 用户，
      ;; 在 overlayfs 上这会触发整棵 store 的 copy-up，导致该服务失败或耗尽
      ;; 内存，于是 guix-daemon 永远起不来，/var/guix/daemon-socket/socket
      ;; 也就不存在（guix pull 报 ENOENT）。
      (privileged? #t)
      (substitute-urls
       '("https://ci.guix.moe"
         "https://mirror.sjtu.edu.cn/guix"
         "https://mirror.sjtu.edu.cn/guix-bordeaux"
         "https://ci.guix.gnu.org"
         "https://bordeaux.guix.gnu.org"))
      (channels
       (list
        (channel
         (name 'rustup)
         (url
          "https://github.com/declantsien/guix-rustup"))
        (channel
         (name 'rosenthal)
         (url
          "https://codeberg.org/hako/rosenthal.git")
         (branch
          "trunk"))
        (channel
         (name 'chorong)
         (url
          "https://github.com/po1onius/cchanl"))
        (channel
         (name 'nonguix)
         (url
          "https://gitlab.com/nonguix/nonguix"))
        (channel
         (name 'guix)
         (url
          "https://codeberg.org/guix/guix.git")
         (introduction
          (make-channel-introduction
           "9edb3f66fd807b096b48283debdcddccfea34bad"
           (openpgp-fingerprint
            "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))))))))

 ;; The bootloader and file-systems are inherited from the official
 ;; installation OS.  The ISO image builder replaces the root file system
 ;; with its ISO9660/live root automatically.
 )
