#!/usr/bin/zsh
zmodload zsh/mathfunc

# EFI is currently not supported

if [ $USERNAME != root ]; then
    echo Must run as root
    exit 1
fi

if [ ! -n "${USER+1}" ]; then
    USER=sizur
fi

if [ ! -n "${DEVICE+1}" ]; then
    DEVICE=/dev/sda
fi

if [ ! -n "${SWAP+1}" ]; then
    SWAP_GB=2
else
    SWAP_GB=$(( $SWAP_GB + 0 ))
fi

if [ ! -n "${ROOT_SIZE_GB+1}" ]; then
    ROOT_GB=20
else
    ROOT_GB=$(( $ROOT_SIZE_GB + 0 ))
fi

if [ ! -n "${HOSTNAME+1}" ]; then
    HOSTNAME=arch-vbox
fi

if [ ! -n "${TIMEZONE+1}" ]; then
    TIMEZONE=America/Los_Angeles
else
    if [ ! -f /usr/share/zoneinfo/$TIMEZONE ]; then
        echo $TIMEZONE is not a legal TZ value. See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
        exit 1
    fi
fi

if [ ! -n "${LOCALE+1}" ]; then
    LOCALE=en_US.UTF-8
else
    if [[ $(grep "$LOCALE" /etc/locale.gen | wc -l) == 0 ]]; then
        echo $LOCALE is not legal. See /etc/locale.gen
        exit 1
    fi
fi


check_command() {
    local CMD=$1
    command -v $CMD > /dev/null 2>&1;
    if [[ $? != 0 ]]; then
        echo Expected command $CMD is not found!
        exit 2
    fi
}

for cmd in cat echo cat grep awk sed mkdir ln sgdisk mkswap swapon mkfs.ext4 mount efivar pacstrap genfstab pacman arch-chroot locale-gen mkinitcpio
do
    check_command $cmd
done

efivar -l > /dev/null 2>&1
if [[ $? == 0 ]]; then
    echo The VM needs to be configured without EFI
    exit 3
fi

sgdisk -p $DEVICE > /dev/null 2>&1
if [[ $? != 0 ]]; then
    echo Bad device: $DEVICE
    exit 4
fi

ping -c 1 kernel.org > /dev/null 2>&1
if [[ $? != 0 ]]; then
    echo No connection!
    exit 4
fi

RAM_BYTES=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
# SWAP_KB=$(( int( $RAM_BYTES * $SWAP_FACTOR / 1024 ) ))

sgdisk -og $DEVICE
if [[ $? != 0 ]]; then
    echo Failed to create MBR Partition
    exit 5
fi

sgdisk -n 1:0:+2M -c 1:"BIOS Boot" -t 1:ef02 $DEVICE
if [[ $? != 0 ]]; then
    echo Failed to create BIOS Boot Partition
    exit 5
fi

sgdisk -n 2:0:+${SWAP_GB}G -c 2:"Swap" -t 2:8200 $DEVICE
if [[ $? != 0 ]]; then
    echo Failed to create Swap Partition
    exit 5
fi

sgdisk -n 3:0:+${ROOT_SIZE_GB}G -c 3:"Root" -t 3:8304 $DEVICE
if [[ $? != 0 ]]; then
    echo Failed to create Root Partition
    exit 5
fi

sgdisk -n 4:0:0 -c 4:"Home" -t 4:8302 $DEVICE
if [[ $? != 0 ]]; then
    echo Failed to create Home Partition
    exit 5
fi

mkswap ${DEVICE}2
if [[ $? != 0 ]]; then
    echo Failed to prepare Swap
    exit 6
fi

swapon ${DEVICE}2
if [[ $? != 0 ]]; then
    echo Failed to use Swap
    exit 6
fi

mkfs.ext4 -L Root ${DEVICE}3
if [[ $? != 0 ]]; then
    echo Failed to format Root partition
    exit 7
fi

mkfs.ext4 -L Home ${DEVICE}4
if [[ $? != 0 ]]; then
    echo Failed to format Home partition
    exit 7
fi

mount ${DEVICE}3 /mnt
if [[ $? != 0 ]]; then
    echo Failed to mount Root
    exit 8
fi

mkdir -p /mnt/home
if [[ $? != 0 ]]; then
    echo Failed to mkdir /home
    exit 9
fi

mount ${DEVICE}4 /mnt/home
if [[ $? != 0 ]]; then
    echo Failed to mount Home
    exit 8
fi

wget -nv -O - 'https://www.archlinux.org/mirrorlist/?protocol=https&ip_version=4&use_mirror_status=on' | egrep 'berkeley|kernel|mtu' | sed -e 's/^#//' > /etc/pacman.d/mirrorlist.bak && rankmirrors /etc/pacman.d/mirrorlist.bak > /etc/pacman.d/mirrorlist
if [[ $? != 0 ]]; then
    echo Failed to get https mirrors
    exit 9
fi

pacstrap /mnt base
if [[ $? != 0 ]]; then
    echo Failed to bootstrap
    exit 10
fi

genfstab -U -p /mnt > /mnt/etc/fstab
if [[ $? != 0 ]]; then
    echo Failed to copy fstab
    exit 11
fi

echo $HOSTNAME > /etc/hostname
if [[ $? != 0 ]]; then
    echo Failed to create /etc/hostname
    exit 12
fi

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
if [[ $? != 0 ]]; then
    echo Failed to set timezone
    exit 12
fi

arch-chroot /mnt
if [[ $? != 0 ]]; then
    echo Failed to arch-chroot
    exit 13
fi

sed -i 's/^#$LOCALE/$LOCALE/' /etc/locale.gen
if [[ $? != 0 ]]; then
    echo Failed to modify /etc/locale.gen
    exit 14
fi

locale-gen
if [[ $? != 0 ]]; then
    echo Failed to generate locale
    exit 14
fi

echo LANG=$LOCALE > /etc/locale.conf
if [[ $? != 0 ]]; then
    echo Failed to configure locale
    exit 15
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
