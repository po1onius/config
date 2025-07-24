(use-modules
 (gnu)
 (gnu packages shells)
 (gnu packages linux)
 (nongnu packages linux)
 (nongnu system linux-initrd)
 (gnu services networking)
 (gnu services desktop)
 (gnu services sound)
 (gnu services dbus)
 (gnu services containers)
 (guix channels))


(operating-system
 (kernel linux)
 (firmware (list linux-firmware))
 (initrd microcode-initrd)
 (locale "zh_CN.utf8")
 (timezone "Asia/Shanghai")
 (keyboard-layout (keyboard-layout "us"))
 (host-name "guix-PC")

 (users (cons (user-account
	       (name "srus")
	       (comment "srus")
	       (shell (file-append fish "/bin/fish"))
	       (group "users")
	       (home-directory "/home/srus")
	       (supplementary-groups '("wheel" "netdev" "audio" "video" "input")))
	      %base-user-accounts))

 (packages %base-packages)

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
    (service rootless-podman-service-type)
    (service alsa-service-type))
   (modify-services
    %base-services
    (guix-service-type
     config => (guix-configuration
		(inherit config)
		(privileged? #f)
		(channels
		 (append
		  (list
		   (channel
		    (name 'rustup)
		    (url "https://github.com/declantsien/guix-rustup"))
		   (channel
		    (name 'rosenthal)
		    (url "https://codeberg.org/hako/rosenthal.git")
		    (branch "trunk"))
		   (channel
		    (name 'nonguix)
		    (url "https://gitlab.com/nonguix/nonguix")))
		  %default-channels))
		(http-proxy "http://127.0.0.1:7890"))))))

 (bootloader (bootloader-configuration
              (bootloader grub-efi-bootloader)
              (targets (list "/boot/efi"))
              (keyboard-layout keyboard-layout)))

 (file-systems
  (append
   (list
    (file-system
     (mount-point "/boot/efi")
     (device (uuid "7468-8C84" 'fat32))
     (type "vfat"))
    (file-system
     (mount-point "/")
     (device (uuid "000034b6-7e73-4b29-90bc-cd90dc4a59b2" 'ext4))
     (type "ext4")))
   %base-file-systems)))
