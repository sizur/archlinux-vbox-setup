# archlinux-vbox-setup
Setup ArchLinux VirtualBox

## Installation

1. Get latest VBox from https://www.virtualbox.org/wiki/Downloads
2. Check checksum
3. Get latest ISO from https://www.archlinux.org/download/
4. Check checksum
5. Create new VM without EFI support
6. Boot the new VM
7. Remove the ISO if you don't want interactive reboots
8. run `USER=<username> zsh -c "$(wget -O - https://goo.gl/mEkAm9)"`

### Variables

* `USER`: Username. Defaults to `sizur`
* `DEVICE`: What device to install to. Defaults to `/dev/sda`
* `SWAP_GB`: Size of swap partition in GiB. Defaults to 2. Assuming no hybernation.
* `ROOT_SIZE_GB`: Size of the Root partition in GiB. Defaults to 20.
