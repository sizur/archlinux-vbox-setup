# archlinux-vbox-setup
Setup VirtualBox ArchLinux Guest

## Installation

1. Get latest VBox from https://www.virtualbox.org/wiki/Downloads
2. Check checksum
3. Get latest ISO from https://www.archlinux.org/download/
4. Check checksum
5. Create new VM without EFI support
6. Boot the new VM
7. If you are on Wifi, setup connection with https://wiki.archlinux.org/index.php/Wireless_network_configuration
8. Remove the ISO if you don't want interactive reboots
9. run `HOSTNAME=<hostname> NAMEUSER=<username> zsh -c "$(wget -O - https://goo.gl/mEkAm9)"`

### Variables

* `NAMEUSER`: Username. Defaults to `sizur`. It's called NAMEUSER to avoid name collision of existing env vars.
* `DEVICE`: What device to install to. Defaults to `/dev/sda`
* `SWAP_GB`: Size of swap partition in GiB. Defaults to 2. Assuming no hybernation.
* `ROOT_SIZE_GB`: Size of the Root partition in GiB. Defaults to 20.
* `HOSTNAME`: Defaults to `arch-vbox`.
* `TIMEZONE`: Defaults to `America/Los_Angeles`. See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
* `LOCALE`: Defaults to `en_US.UTF-8`
