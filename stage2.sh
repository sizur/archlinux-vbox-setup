#!/usr/bin/zsh

source /root/stage2.env

check_command() {
    local CMD=$1
    command -v $CMD > /dev/null 2>&1;
    if [[ $? != 0 ]]; then
        echo Expected command $CMD is not found!
        exit 2
    fi
}

for cmd in cat echo cat grep awk sed mkdir ln pacman wget locale-gen mkinitcpio grub-install grub-mkconfig systemctl useradd gpasswd
do
    check_command $cmd
done

locale-gen
if [[ $? != 0 ]]; then
    echo Failed to generate locale
    exit 14
fi

mkinitcpio -p linux
if [[ $? != 0 ]]; then
    echo Failed to create initcpio
    exit 16
fi

grub-install --recheck $DEVICE
if [[ $? != 0 ]]; then
    echo Failed to install GRUB
    exit 18
fi

grub-mkconfig -o /boot/grub/grub.cfg
if [[ $? != 0 ]]; then
    echo Failed to configure GRUB
    exit 19
fi

echo SUBSYSTEM==\"net\", ACTION==\"add\", ATTR{address}==\"`ip addr show \`ls /sys/class/net --color=never | egrep "^wl|^en"\` | grep link/ | awk '{print $2}'`\", NAME=\"net1\" > /etc/udev/rules.d/10-network.rules && cat /etc/udev/rules.d/10-network.rules
if [[ $? != 0 ]]; then
    echo Failed to rename network device to net1
    exit 20
fi

systemctl enable dhcpcd@net1.service
if [[ $? != 0 ]]; then
    echo Failed to enable net1
    exit 21
fi

pacman --noconfirm -S net-tools pkgfile xf86-video-vesa sudo git openssh autofs tmux nfs-utils arch-inall-scripts
if [[ $? != 0 ]]; then
    echo Failed to install basics
    exit 21
fi

useradd -m -g users -G wheel,uucp,rfkill,games -s /usr/bin/zsh $USER
if [[ $? != 0 ]]; then
    echo Failed to add user
    exit 21
fi

systemctl enable rpcbind
if [[ $? != 0 ]]; then
    echo Failed to enable rpcbind
    exit 21
fi

pacman --noconfirm -S xorg-server xorg-server-utils xorg xorg-apps xorg-xinit xterm xorg-xclock ttf-dejavu ttf-droid ttf-inconsolata terminus-font
if [[ $? != 0 ]]; then
    echo Failed to install X
    exit 21
fi

pacman --noconfirm -S emacs virtualbox-guest-utils xmonad xmonad-contrib pulseaudio pulseaudio-alsa xcompmgr rxvt-unicode urxvt-perls dzen2 conky dmenu weechat
if [[ $? != 0 ]]; then
    echo Failed to install emacs,guest-addons,xmonad,sound
    exit 21
fi

modprobe -a vboxguest vboxsf vboxvideo
if [[ $? != 0 ]]; then
    echo Failed to modprobe vbox
    exit 21
fi

sh -c 'echo "vboxguest\nvboxsf\nvboxvideo" > /etc/modules-load.d/virtualbox.conf'
if [[ $? != 0 ]]; then
    echo Failed to install vmoxfs module
    exit 21
fi

systemctl enable vboxservice.service
if [[ $? != 0 ]]; then
    echo Failed to enable vbox service
    exit 21
fi

gpasswd --add $USER vboxsf
if [[ $? != 0 ]]; then
    echo Failed to add $USER to vboxsf group
    exit 21
fi

su $USER -c 'zsh -c "mkdir ~/git && cd git && git clone https://github.com/sizur/dotfiles.git && cd dotfiles && make update && make install"'
if [[ $? != 0 ]]; then
    echo Failed final setup
    exit 21
fi
