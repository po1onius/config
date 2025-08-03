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
       (append
        (list
         "https://mirror.sjtu.edu.cn/guix")
        %default-substitute-urls))
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
         (name 'abbe)
         (url "https://codeberg.org/group/guix-modules.git")
         (branch "mainline")
         (introduction
          (make-channel-introduction
           "8c754e3a4b49af7459a8c99de130fa880e5ca86a"
           (openpgp-fingerprint
            "F682 CDCC 39DC 0FEA E116  20B6 C746 CFA9 E74F A4B0"))))
        (channel
         (name 'guix)
         (url
          "https://codeberg.org/guix/guix.git")
         (introduction
          (make-channel-introduction
           "9edb3f66fd807b096b48283debdcddccfea34bad"
           (openpgp-fingerprint
            "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))))
      (http-proxy
       "http://127.0.0.1:7890"))))))

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
     (device (uuid "F97A-F1DA"
                   'fat32))
     (type "vfat"))
    (file-system
     (mount-point "/")
     (device (uuid
              "7b606f38-4cbd-4a1d-ae5f-1d55e6b1cae0"
              'ext4))
     (type "ext4"))) %base-file-systems)))
