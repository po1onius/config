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
 (kernel linux)
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
                            "input" "cgroup")))
   %base-user-accounts))

 (packages (cons git %base-packages))

 (services
  (append
   (list
    (service elogind-service-type
             (elogind-configuration
              (handle-power-key 'ignore)))
    (service bluetooth-service-type)
    (service iwd-service-type)
    (service dhcpcd-service-type)
    (service polkit-service-type)
    (service iptables-service-type)
    (service dae-service-type
             (dae-service-configuration (config-file "/home/srus/.config/dae/config.dae")))
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
    (service alsa-service-type))
   (modify-services
    %base-services
    (guix-service-type
     config =>
     (guix-configuration
      (inherit config)
      (privileged? #f)
      (substitute-urls
       '("https://mirror.sjtu.edu.cn/guix"
         "https://ci.guix.moe"
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
