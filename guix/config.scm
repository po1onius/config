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
		 (name "guix")
		 (comment "shadow")
		 (shell (file-append fish "/bin/fish"))
		 (group "users")
		 (home-directory "/home/guix")
		 (supplementary-groups '("wheel" "netdev" "audio" "video" "input")))
	       %base-user-accounts))

  (packages %base-packages)

  (services (append (list (service elogind-service-type
			    (elogind-configuration
			      (handle-power-key 'ignore)))
		   (service wpa-supplicant-service-type)
		   (service bluetooth-service-type)
		   (service network-manager-service-type)
			(service polkit-service-type)
		   (service alsa-service-type))
		   (modify-services %base-services
				    (guix-service-type
				      config => (guix-configuration
						  (inherit config)
						  (channels (list
							      (channel
								(inherit (car %default-channels))
								(url "https://codeberg.org/guix/guix-mirror"))
							      (channel
							        (name 'rustup)
								(url "https://github.com/declantsien/guix-rustup"))
							      (channel
								   (name 'rosenthal)
   (url "https://codeberg.org/hako/rosenthal.git")
   (branch "trunk"))
							      (channel
								(name 'nonguix)
								(url "https://gitlab.com/nonguix/nonguix"))))
						  (http-proxy "http://127.0.0.1:7890"))))))

  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets (list "/boot/efi"))
                (keyboard-layout keyboard-layout)))

  (file-systems (append (list (file-system
                         (mount-point "/boot/efi")
                         (device (uuid "CB39-D616" 'fat32))
                         (type "vfat"))
                       (file-system
                         (mount-point "/")
                         (device (uuid "e68d37d0-fd79-450f-af45-56e084d600bf" 'ext4))
                         (type "ext4")))
		       %base-file-systems)))
