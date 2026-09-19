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
)

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
     (device (uuid "9074-DBF7"
                   'fat32))
     (type "vfat"))
    (file-system
     (mount-point "/")
     (device (uuid
              "8644af7e-f898-439f-87a6-5590b990c1b5"
              'ext4))
     (type "ext4"))) %base-file-systems)))
