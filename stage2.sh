#!/usr/bin/zsh

source /root/stage2.env

check_command() {
    local CMD=$1
    command -v $CMD > /dev/null 2>&1;
    if [[ $? != 0 ]]; then
        echo Expected command $CMD is not found!
        exit 26
    fi
}

check-command pacman
pacman --noconfirm -S grub os-prober
if [[ $? != 0 ]]; then
    echo Failed to install GRUB
    exit 27
fi

for cmd in cat wc echo cat grep awk sed mkdir ln wget locale-gen mkinitcpio grub-install grub-mkconfig systemctl useradd passwd gpasswd
do
    check_command $cmd
done

sed -i "s/^#$LOCALE/$LOCALE/" /etc/locale.gen
if [[ $? != 0 ]]; then
    echo Failed to modify /etc/locale.gen
    exit 28
fi
if [[ $(grep "^$LOCALE" /etc/locale.gen | wc -l) == 0 ]]; then
    echo Failed to modify /etc/locale.gen
    exit 29
fi

locale-gen
if [[ $? != 0 ]]; then
    echo Failed to generate locale
    exit 30
fi

echo "LANG=$LOCALE" > /etc/locale.conf
if [[ $? != 0 ]]; then
    echo Failed to configure locale
    exit 31
fi

mkinitcpio -p linux
if [[ $? != 0 ]]; then
    echo Failed to create initcpio
    exit 32
fi

grub-install --recheck $DEVICE
if [[ $? != 0 ]]; then
    echo Failed to install GRUB
    exit 33
fi

grub-mkconfig -o /boot/grub/grub.cfg
if [[ $? != 0 ]]; then
    echo Failed to configure GRUB
    exit 34
fi

echo SUBSYSTEM==\"net\", ACTION==\"add\", ATTR{address}==\"`ip addr show \`ls /sys/class/net --color=never | egrep "^wl|^en"\` | grep link/ | awk '{print $2}'`\", NAME=\"net1\" > /etc/udev/rules.d/10-network.rules && cat /etc/udev/rules.d/10-network.rules
if [[ $? != 0 ]]; then
    echo Failed to rename network device to net1
    exit 35
fi

systemctl enable dhcpcd@net1.service
if [[ $? != 0 ]]; then
    echo Failed to enable net1
    exit 36
fi

if [ $DOMAIN != 0 ]; then
    echo "option domain-name \"$DOMAIN\"" >> /etc/resolv.conf
    if [[ $? != 0 ]]; then
        echo Failed to add domain to /etc/resolve.conf
        exit 37
    fi
fi

pacman --noconfirm -S net-tools pkgfile xf86-video-vesa sudo git openssh autofs tmux nfs-utils arch-install-scripts rsync
if [[ $? != 0 ]]; then
    echo Failed to install basics
    exit 38
fi

useradd -m -g users -G wheel,uucp,rfkill,games -s /usr/bin/zsh $NAMEUSER
if [[ $? != 0 ]]; then
    echo Failed to add user
    exit 39
fi

# susoers needs to be modified by visudo.
# this temp script invoked visudo with itself as the editor
check_command visudo
cat <<eos > /root/stage2.sudo
#!/usr/bin/zsh
if [ -z "\$1" ]; then
  export EDITOR=\$0 && visudo
else
  if [ -z "\$2" ]; then
    FILE="\$1"
  else
    FILE="\$2"
  fi
  echo "Changing sudoers"
  if [ \$(egrep '^%wheel ALL=\\(ALL\\) NOPASSWD: ALL' "\$FILE" | wc -l) != 0 ]; then
    exit 0
  fi
  if [ \$(egrep '^# %wheel ALL=\\(ALL\\) NOPASSWD: ALL' "\$FILE" | wc -l) != 0 ]; then
    echo 'modifying in place'
    sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/'  "\$FILE"
  else
    echo 'adding'
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> "\$FILE"
  fi
fi
eos
chmod +x /root/stage2.sudo
if [[ $? != 0 ]]; then
    echo Failed to change sudoers
    exit 100
fi
/root/stage2.sudo
if [[ $? != 0 ]]; then
    echo Failed to change sudoers
    exit 40
fi
rm /root/stage2.sudo

systemctl enable rpcbind
if [[ $? != 0 ]]; then
    echo Failed to enable rpcbind
    exit 41
fi

pacman --noconfirm -S xorg-server xorg-server-utils xorg xorg-apps xorg-xinit xterm xorg-xclock xorg-xlsfonts ttf-dejavu ttf-droid ttf-inconsolata terminus-font
if [[ $? != 0 ]]; then
    echo Failed to install X
    exit 42
fi

pacman --noconfirm -S emacs virtualbox-guest-utils xmonad xmonad-contrib pulseaudio pulseaudio-alsa pamixer xcompmgr rxvt-unicode urxvt-perls dzen2 conky dmenu scrot weechat
if [[ $? != 0 ]]; then
    echo Failed to install guest-addons and apps
    exit 43
fi

modprobe -a vboxguest vboxsf vboxvideo
if [[ $? != 0 ]]; then
    echo Failed to modprobe vbox
    exit 44
fi

echo "vboxguest\nvboxsf\nvboxvideo" > /etc/modules-load.d/virtualbox.conf
if [[ $? != 0 ]]; then
    echo Failed to install vmoxfs module
    exit 45
fi

systemctl enable vboxservice.service
if [[ $? != 0 ]]; then
    echo Failed to enable vbox service
    exit 46
fi

gpasswd --add $NAMEUSER vboxsf
if [[ $? != 0 ]]; then
    echo Failed to add $NAMEUSER to vboxsf group
    exit 47
fi

su $NAMEUSER -c 'zsh -c "mkdir ~/git && cd ~/git && git clone https://github.com/sizur/dotfiles.git && cd dotfiles && make update && make install"'
if [[ $? != 0 ]]; then
    echo Failed final setup
    exit 48
fi

echo Please enter new password for root
passwd
if [[ $? != 0 ]]; then
    echo Failed to set password for root
    exit 49
fi

echo Please enter new password for $NAMEUSER
passwd $NAMEUSER
if [[ $? != 0 ]]; then
    echo Failed to set password for $NAMEUSER
    exit 50
fi
