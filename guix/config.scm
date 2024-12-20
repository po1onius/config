(use-modules
  (gnu)
  (gnu packages certs)
  (gnu packages shells)
  (nongnu packages linux)
  (nongnu system linux-initrd)
  (gnu services networking)
  (gnu services desktop)
  (gnu services sound)
  (guix channels))


(operating-system
  (kernel linux)
  (firmware (list linux-firmware))
  (initrd microcode-initrd)
  (locale "en_US.utf8")
  (timezone "Asia/Shanghai")
  (keyboard-layout (keyboard-layout "us"))
  (host-name "guix")

  (users (cons (user-account
		 (name "srus")
		 (comment "srus")
		 (shell (file-append fish "/bin/fish"))
		 (group "users")
		 (home-directory "/home/srus")
		 (supplementary-groups '("wheel" "netdev" "audio" "video")))
	       %base-user-accounts))

  (packages %base-packages)

  (services (cons* (service elogind-service-type
			    (elogind-configuration
			      (handle-power-key 'ignore)))
		   (service wpa-supplicant-service-type)
		   (service network-manager-service-type)
		   (service alsa-service-type)
		   (modify-services %base-services
				    (guix-service-type
				      config => (guix-configuration
						  (inherit config)
						  (channels (list
							      (channel
								(inherit (car %default-channels))
								(url "https://mirror.sjtu.edu.cn/git/guix.git"))
							      (channel
								(name 'nonguix)
								(url "https://gitlab.com/nonguix/nonguix"))))
						  (http-proxy "http://127.0.0.1:7890"))))))

  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets (list "/boot/efi"))
                (keyboard-layout keyboard-layout)))

  (file-systems (cons* (file-system
                         (mount-point "/boot/efi")
                         (device (uuid "089E-51D3" 'fat32))
                         (type "vfat"))
                       (file-system
                         (mount-point "/")
                         (device (uuid "9fbe997b-3aef-4716-8608-792021613443" 'ext4))
                         (type "ext4"))
		       %base-file-systems)))
