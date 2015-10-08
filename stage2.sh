
check_command() {
    local CMD=$1
    command -v $CMD > /dev/null 2>&1;
    if [[ $? != 0 ]]; then
        echo Expected command $CMD is not found!
        exit 2
    fi
}

for cmd in cat echo cat grep awk sed mkdir ln pacman wget locale-gen mkinitcpio
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

pacman --noconfirm -S grub os-prober
if [[ $? != 0 ]]; then
    echo Failed to install GRUB package
    exit 17
fi

for cmd in grub-install grub-mkconfig systemctl
do
    check_command $cmd
done

grub-install --recheck
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

reboot
