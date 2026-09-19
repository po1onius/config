(use-modules
 (gnu)
 (gnu packages shells)
 (gnu packages linux)
 (gnu packages window-management)
 (gnu packages version-control)
 (nongnu packages linux)
 (nongnu system linux-initrd)
 (gnu services networking)
 (gnu services desktop)
 (gnu services sound)
 (gnu services dbus)
 (gnu services containers)
 (gnu services xorg)
 (ch0r0ng services networking)
 (ch0r0ng services clash-verge)
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

(define %boot-label "BOOT")
(define %root-label "ROOT")

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
    (name "liz")
    (comment "liz")
    (shell (file-append fish "/bin/fish"))
    (group "users")
    (home-directory "/home/liz")
   (supplementary-groups '("wheel" "netdev" "audio" "video"
                            "input" "clash-verge")))
   %base-user-accounts))

 (packages (cons* niri git %base-packages))

 (services
  (append
   (list
    (service gdm-service-type)
    (service elogind-service-type
             (elogind-configuration
              (handle-power-key 'ignore)))
    (service bluetooth-service-type)
    (service iwd-service-type)
    (service dhcpcd-service-type)
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