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
    (service gnome-desktop-service-type)
    (service elogind-service-type
             (elogind-configuration
              (handle-power-key 'ignore)))
    (service dhcpcd-service-type)
    (service rootless-podman-service-type
             (rootless-podman-configuration
              (subgids
               (list
                (subid-range
                 (name
                  "srus"))))
              (subuids
               (list
                (subid-range
                 (name
                  "srus"))))))
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
   (targets (list "/boot"))
   (keyboard-layout keyboard-layout)))

 (file-systems
  (append
   (list
    (file-system
     (mount-point "/boot")
     (device (uuid "EF9B-4D6D"
                   'fat32))
     (type "vfat"))
    (file-system
     (mount-point "/")
     (device (uuid
              "6324f9fd-e555-49be-8f7b-8950349fecd8"
              'ext4))
     (type "ext4"))) %base-file-systems)))
