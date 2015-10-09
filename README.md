# archlinux-vbox-setup
Setup VirtualBox ArchLinux Guest with XMonad, Emacs, rxvt-unicode, oh-my-zsh, tmux customizations from https://github.com/sizur/dotfiles

## Installation

1. Get latest VBox from https://www.virtualbox.org/wiki/Downloads
2. Check checksum
3. Get latest ISO from https://www.archlinux.org/download/
4. Check checksum
5. Create new VM without EFI support
6. Boot the new VM
7. If you are on Wifi, setup connection with https://wiki.archlinux.org/index.php/Wireless_network_configuration
8. Run `HOSTNAME=<hostname> NAMEUSER=<username> zsh -c "$(wget -O - https://goo.gl/mEkAm9)"`
9. The installer will ask for new root and `NAMEUSER` passwords
10. Once presented with oh-my-zsh successful installation, type `exit`.
11. When the installer will restart, make sure you dont boot from the ISO.

### Variables

* `NAMEUSER`: Username. Defaults to `sizur`. It's called `NAMEUSER` to avoid name collision of existing env vars.
* `DEVICE`: What device to install to. Defaults to `/dev/sda`. **ATTENTION:** this will rease your data!
* `SWAP_GB`: Size of swap partition in GiB. Defaults to 2. Assuming no hybernation.
* `ROOT_GB`: Size of the Root partition in GiB. Defaults to 20.
* `HOSTNAME`: Defaults to `arch-vbox`.
* `DOMAIN` : Used to resolve naked hostnames. Defaults to none. Can list more than one using a string with a space separator.
* `TIMEZONE`: Defaults to `America/Los_Angeles`. See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
* `LOCALE`: Defaults to `en_US.UTF-8`

## Usage

After login, type `startx` to enter the XMonad.

Modifiers:
* `W` is the `Windows` key.
* `C` is the `Ctrl` key.
* `M` is the `Alt` key.
* `S` is the `Shift` key.

The following are my most frequently used commands.

### XMonad

* `W-1`, `W-2`, etc... Switches XMonad desktops.
* `W-S-Enter` opens a new terminal.
* `W-p` runs dmenu so you can execute any windowed application.
* `W-S-c` kills current window.
* `M-C-c` copies current selection to clipboard.
* `W-Tab` focus next window.
* `W-S-Tab` focus previous window.
* `W-Space` change to next layout.
* `W-q` reload xmonad configuration.
* `W-S-q` exit xmonad.

