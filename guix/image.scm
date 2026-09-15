(use-modules
 (gnu)
 (gnu packages shells)
 (gnu packages linux)
 (gnu packages version-control)
 (nongnu packages linux)
 (nongnu system linux-initrd)
 (gnu services networking)
 (gnu services desktop)
 (gnu services sound)
 (gnu services dbus)
 (gnu services containers)
 (ch0r0ng services networking)
 (gnu system accounts)
 (guix channels))

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
    (name "srus")
    (comment "srus")
    (shell (file-append fish "/bin/fish"))
    (group "users")
    (home-directory "/home/srus")
   (supplementary-groups '("wheel" "netdev" "audio" "video"
                            "input")))
   %base-user-accounts))

 (packages (cons git %base-packages))

 (services
  (append
   (list
    (service gnome-desktop-service-type))
   (modify-services
    %base-services
    (guix-service-type
     config =>
     (guix-configuration
      (inherit config)
      (privileged? #f)
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
            "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))))))))

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
     (device (file-system-label "EFI-SYSTEM"))
     (type "vfat"))
    (file-system
     (mount-point "/")
     (device (file-system-label "GUIX-ROOT"))
     (type "ext4"))) %base-file-systems)))
