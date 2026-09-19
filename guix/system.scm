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
 (gnu build file-systems)          ;find-partition-by-label、read-partition-uuid
 (gnu system uuid)                 ;bytevector->uuid
 (ice-9 match)                     ;匹配 /proc/self/mountinfo 的字段
 (ice-9 rdelim)                    ;read-line
 )

;; 不再把 UUID 写死在配置里，而是在求值配置时到设备上读取真实的文件系统
;; UUID，这样换盘、重装之后无需改配置，也不依赖具体盘序。
;;
;; 三个互备的定位方式，按顺序尝试：
;;   1. #:label       —— 按文件系统标签找，最稳，和盘序、设备名都无关；
;;   2. #:device      —— 直接给块设备文件，如 "/dev/nvme0n1p2"；
;;   3. #:mount-point —— 从 /proc/self/mountinfo 反查该挂载点当前用的设备。
;;                       全新安装时磁盘挂在 /mnt 下，正是靠这一条自动认盘。
;;
;; 注意：读取超级块需要 root 权限，设备节点也必须已经存在（udev 就绪），
;; 所以请在正在运行的目标系统、或 LiveCD 安装环境里以 root 求值，例如：
;;   sudo guix system reconfigure ~/config/guix/system.scm
;;   sudo guix system init ~/config/guix/system.scm /mnt

(define (uuid-bytes->uuid bv type)
  "把 read-partition-uuid 读到的字节向量 BV 变成带类型 TYPE 的 UUID 对象，
长度不符（DCE UUID 16 字节、FAT UUID 4 字节）时报错，避免张冠李戴。"
  (define expected (if (memq type '(fat fat16 fat32 exfat)) 4 16))
  (unless (and bv (= (bytevector-length bv) expected))
    (raise (format #f "读到的 UUID 字节数 ~s 与 ~a 不符（应为 ~a 字节）"
                   (and bv (bytevector-length bv)) type expected)))
  (bytevector->uuid bv type))

(define (device-for-mount-point mount-point)
  "从 /proc/self/mountinfo 里查出 MOUNT-POINT 当前对应的设备名，没有则 #f。
每行的字段是：id parent major:minor root MOUNTPOINT opts [optional...] - fstype SOURCE superopts
MOUNT-POINT 也可以是一个候选列表，按顺序返回第一个命中的设备。"
  (define (lookup point)
    (call-with-input-file "/proc/self/mountinfo"
      (lambda (port)
        (let loop ()
          (let ((line (read-line port)))
            (cond
             ((eof-object? line) #f)
             (else
              (let ((fields (string-tokenize line)))
                (match fields
                  ((_ _ _ _ root-point _ ...)
                   (if (string=? root-point point)
                       (match (member "-" fields)
                         ((_ fstype source _ ...) source)
                         (_ #f))
                       (loop)))
                  (_ (loop)))))))))))

  (if (list? mount-point)
      (let loop ((points mount-point))
        (and (pair? points)
             (or (lookup (car points)) (loop (cdr points)))))
      (lookup mount-point)))

(define (read-uuid-by-label label type)
  "按文件系统标签 LABEL 查找分区并读取其 UUID，找不到返回 #f。"
  (let ((partition (find-partition-by-label label)))
    (and partition
         (false-if-exception
          (uuid-bytes->uuid (read-partition-uuid partition) type)))))

(define* (detect-uuid type #:key device label mount-point)
  "在求值配置时检测文件系统 UUID，依次尝试 LABEL、DEVICE、MOUNT-POINT
三种定位方式，返回带 TYPE（如 'ext4、'fat32）的 UUID 对象。全都失败时
直接报错，避免生成一份静悄悄坏掉的配置。"
  (let* ((from-mount (and mount-point (device-for-mount-point mount-point)))
         (found (or (and label (read-uuid-by-label label type))
                    (and device
                         (false-if-exception
                          (uuid-bytes->uuid (read-partition-uuid device) type)))
                    (and from-mount
                         (false-if-exception
                          (uuid-bytes->uuid (read-partition-uuid from-mount) type))))))
    (unless found
      (raise (format #f "检测不到 ~a 文件系统的 UUID（label=~s device=~s mount-point=~s 解析为 ~s）"
                     type label device mount-point from-mount)))
    found))

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
     ;; 自动检测 ESP 的 FAT UUID。三种定位方式按顺序尝试，任一成功即可：
     ;;   装了标签：  (detect-uuid 'fat32 #:label "GUIX_ESP")
     ;;   日常重配：  #:device "/dev/nvme0n1p1"
     ;;   全新安装：  #:mount-point "/mnt/boot/efi"（LiveCD 里 ESP 挂这儿）
     (device (detect-uuid 'fat32
                          #:device "/dev/nvme0n1p1"
                          #:mount-point '("/boot/efi" "/mnt/boot/efi")))
     (type "vfat"))
    (file-system
     (mount-point "/")
     ;; 根文件系统同理：平时走 #:device，全新安装时目标盘挂在 /mnt，
     ;; 由 #:mount-point 认出来（注意别在已装好的系统上顺手把根又挂到 /mnt
     ;; 再重配，那样 "/" 会解析成当前正在运行的那个根）。
     (device (detect-uuid 'ext4
                          #:device "/dev/nvme0n1p2"
                          #:mount-point '("/" "/mnt")))
     (type "ext4"))) %base-file-systems)))
