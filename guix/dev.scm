;some useful args
;guix shell --container --network --emulate-fhs --preserve='^DISPLAY$' --preserve='^DBUS_' --expose=/var/run/dbus --expose=/dev/dri --share=/dev/snd --share=/dev/shm --expose=/sys/class/input --expose=/sys/devices --expose=/sys/dev --expose=/sys/bus/pci --expose=/run/user/"$(id -u)" --preserve='^XDG_' --manifest=manifest.scm --preserve='^WAYLAND_DISPLAY$' --preserve='^https_proxy$' --preserve='^UDEV_HWDB_PATH$'



(use-modules
  (gnu packages pkg-config)
  (gnu packages curl)
  (gnu packages certs)
  (gnu packages commencement)
  (rustup build toolchain)
  ;(gnu packages rust)
  ;(gnu packages rust-apps)
  (gnu packages gl)
  (gnu packages vulkan)
  (gnu packages freedesktop)
  (gnu packages linux)
  (gnu packages admin)
  (gnu packages xdisorg))


(packages->manifest
  (list gcc-toolchain
    nss-certs
    coreutils
    curl
	eudev
	pkg-config
    (rustup)
	;rust
	;rust-cargo
	;rust-analyzer
	libxkbcommon
	vulkan-loader
	mesa
	wayland
	alsa-lib))

