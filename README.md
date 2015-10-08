# archlinux-vbox-setup
Setup VirtualBox ArchLinux Guest with xmonad, emacs, urxvt, zsh customizations from https://github.com/sizur/dotfiles

## Installation

1. Get latest VBox from https://www.virtualbox.org/wiki/Downloads
2. Check checksum
3. Get latest ISO from https://www.archlinux.org/download/
4. Check checksum
5. Create new VM without EFI support
6. Boot the new VM
7. If you are on Wifi, setup connection with https://wiki.archlinux.org/index.php/Wireless_network_configuration
8. Run `HOSTNAME=<hostname> NAMEUSER=<username> zsh -c "$(wget -O - https://goo.gl/mEkAm9)"`
9. The installer will ask for new root and $NAMEUSER passwords
10. Once presented with oh-my-zsh successful installation, type `exit`.
11. When the installer will restart, make sure you dont boot from the ISO.

### Variables

* `NAMEUSER`: Username. Defaults to `sizur`. It's called NAMEUSER to avoid name collision of existing env vars.
* `DEVICE`: What device to install to. Defaults to `/dev/sda`. **ATTENTION:** this will rease your data!
* `SWAP_GB`: Size of swap partition in GiB. Defaults to 2. Assuming no hybernation.
* `ROOT_GB`: Size of the Root partition in GiB. Defaults to 20.
* `HOSTNAME`: Defaults to `arch-vbox`.
* `DOMAIN` : Used to resolve hostnames. Defaults to none.
* `TIMEZONE`: Defaults to `America/Los_Angeles`. See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
* `LOCALE`: Defaults to `en_US.UTF-8`
