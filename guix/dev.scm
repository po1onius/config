;some useful args
;guix shell --container --network --emulate-fhs --preserve='^DISPLAY$' --preserve='^DBUS_' --expose=/var/run/dbus --expose=/dev/dri --share=/dev/snd --share=/dev/shm --expose=/sys/class/input --expose=/sys/devices --expose=/sys/dev --expose=/sys/bus/pci --expose=/run/user/"$(id -u)" --preserve='^XDG_' --preserve='^WAYLAND_DISPLAY$' --preserve='^https_proxy$' --preserve='^UDEV_HWDB_PATH$' --manifest=dev.scm


(use-modules
  (helix)
  (gnu packages pkg-config)
  (gnu packages curl)
  (gnu packages webkit)
  (gnu packages gtk)
  (gnu packages llvm)
  (gnu packages build-tools)
  (gnu packages wm)
  (gnu packages base)
  (gnu packages less)
  (gnu packages golang)
  (gnu packages version-control)
  (gnu packages certs)
  (gnu packages commencement)
  (rustup build toolchain)
  (gnu packages gl)
  (gnu packages vulkan)
  (gnu packages freedesktop)
  (gnu packages linux)
  (gnu packages admin)
  (gnu packages xdisorg))


(packages->manifest
  (list gcc-toolchain
        less
        wl-clipboard
        wlroots
        meson
        clang
        webkitgtk
        webkitgtk-with-libsoup2
        gtk+
        gtk
        webkitgtk-for-gtk3
        grep
        helix
        atkmm
        gnu-make
        go
        git
        nss-certs
        coreutils
        curl
	      eudev
	      pkg-config
        (rustup "stable" #:components (list 'rust-analyzer 'rust-src))
	      libxkbcommon
	      vulkan-loader
	      mesa
	      wayland
	      alsa-lib))

