# Dotfiles
my personal dotfiles

## Setup
### Installation
Install stow with your package manager of choice and create a `~/.config` directory,
if you haven't already.

Then just e.g.:
```
mkdir ~/.config
git clone https://github.com/zeratax/dotfiles
cd dotfiles
stow vim
```

And you have installed my `vim` setup.
If you now additionally want to install my i3 setup, just execute `stow i3`.

To easily and quickly install all or multiple dotfiles and their dependencies run:
```
./install.sh
```

### Deinstallation
To remove/unlink dotfiles you can easily just execute in the dotfiles dir e.g.:
```
stow -D vim
```

## Full Setup
This is a complete guide to an arch linux setup, with luks disk encryption, uefi secure boot, brtfs filesystem, followed by user setup and a simple backup system.

This guide is mostly a compilation of:
  - https://wiki.archlinux.org/index.php/installation_guide
  - https://wiki.archlinux.de/title/Anleitung_f%C3%BCr_Einsteiger
  - https://gist.github.com/lagseeing/182bc80ae3954ed79776
  - https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Encrypted_boot_partition_.28GRUB.29
  - https://github.com/xmikos/cryptboot/blob/master/README.md

In this guide I will set my system to german locale, but it should be fairly obvious how to use a different locale.

I'm going to skip all network related setup since that is highly specific to your setup.
On my running system I'm just using GNOME's NetworkManager since it's extremely easy to use and
even works with edu roam without a hassle, during install I plugged in an ethernet cable and conncted with dhcpcd, e.g.:
```
# ip link
1: lo: <LOOPBACK.....
2: enp4s0: <BROADCAST...

# dhcpcd enp4s0
```
Make sure to later disable all other network managing systems so that they don't interfere with your network manager.

### Installation

#### Disk Preperation

##### Partition Layout

Example of a final partition layout with a 250GB SSD.

```
$ lsblk
NAME                     MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda                        8:0    0 238,5G  0 disk  
├─sda1                     8:1    0     1M  0 part  
├─sda2                     8:2    0   512M  0 part  /boot/efi
├─sda3                     8:3    0   200M  0 part  
│ └─cryptboot            254:3    0   198M  0 crypt /boot
└─sda4                     8:4    0 237,8G  0 part  
  └─lvm                  254:0    0 237,8G  0 crypt
    ├─vg-swap            254:1    0     8G  0 lvm   [SWAP]
    └─vg-arch            254:2    0 229,8G  0 lvm   /
```
```
+---------------------+---------------------+----------------+---------------------+----------------------+----------------------+
| BIOS boot partition | ESP partition       | Boot partition |  Logical volume 1   | Btrfs Subvolume      | Btrfs Subvolume      |
|                     |                     |                |                     | @                    | @home                |
|                     |                     |                |                     |                      |                      |
|                     | /boot/efi            | /boot          | [SWAP]              | /                    | /home                |
|                     |                     |                |                     |                      |                      |
|                     |                     |                |                     +----------------------+----------------------+
|                     |                     |                | /dev/mapper/vg-swap | /dev/mapper/vg-arch Logical volume 2        |
| /dev/sda1           | /dev/sda2           | /dev/sda3      +---------------------+----------------------+----------------------+
| unencrypted         | unencrypted         | LUKS encrypted | /dev/sda4 encrypted using LVM on LUKS                             |
+---------------------+---------------------+----------------+-------------------------------------------------------------------+
```

You could most likely do this setup without the unencrypted BIOS boot partition, since for secure boot we'll be exclusively using UEFI.

##### Partitions
Once you're booted into the arch-linux live CD/USB we're going to format the drive.
We'll be using `gdisk` to format the drive, but you're obviously free to use w/e.

```
gdisk /dev/sda
o
y
n
⏎
⏎
+1M
ef02
n
⏎
⏎
+512M
ef00
n
⏎
⏎
+200M
8300
n
⏎
⏎
⏎
8e00
w
```

Now we format the EFI partition as FAT32:
```
# mkfs.fat -F32 /dev/sda2
```

which result in something like this:
```
# gdisk -l /dev/sda
Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048            4095   1024.0 KiB  EF02  BIOS boot partition
   2            4096         1052671   512.0 MiB   EF00  EFI System
   3         1052672         1462271   200.0 MiB   8300  Linux filesystem
   4         1462272       500118158   237.8 GiB   8E00  Linux LVM
```


##### LUKS
*Linux Unified Key Setup*
Now we're going to encrypt the system partition *(/dev/sda4)* and boot partition *(/dev/sda3)*.
Since  we're going to use GRUB *Grand Unified Bootloader* to boot our system, make sure to **NOT** use `--type luks2` on the boot partition, since **GRUB does not support LUKS2!**

```
# cryptsetup luksFormat --type luks2 /dev/sda4
# cryptsetup luksFormat /dev/sda3
```

If you're using an HDD you can just open the encrypted partition with:
```
# cryptsetup luksOpen /dev/sda4 lvm
# cryptsetup luksOpen /dev/sda3 cryptboot
```

For SSDs you could add the `--allow-discards` option,
which enables TRIM support.
TRIM allows your OS to inform the SSD which sectors are no longer considered in use and
should be wiped internally.
**Though be sure to check whether or not your SSD actually supports TRIM
and make your self familiar with the [security drawbacks](https://wiki.archlinux.org/index.php/Dm-crypt/Specialties#Discard.2FTRIM_support_for_solid_state_drives_.28SSD.29).**
To check for TRIM support execute:
```
# lsblk --discard
```
and check if the values for  DISC-GRAN (discard granularity) and DISC-MAX (discard max bytes)
are non-zero.

```
# cryptsetup luksOpen --allow-discards /dev/sda4 lvm
# cryptsetup luksOpen --allow-discards /dev/sda3 cryptboot
```

And finally format the boot partition as ext4 *fourth extended filesystem*:
```
mkfs.ext4 /dev/mapper/cryptboot
```

##### LVM
*Logical Volume Manager*

Since btrfs doesn't support swap partitions we're going to make use of a LVM.

  - Create the physical volume and the volume group:

    ```
    # pvcreate /dev/mapper/lvm
    # vgcreate vg /dev/mapper/lvm
    ```

  - Create the volume for swap and the btrfs partition. Make the swap partition as big as your RAM, here 8G:

    ```
    # lvcreate -L 8G vg -n swap
    # lvcreate -l +100%FREE vg -n arch
    ```
  - Format the volumes:

    ```
    # mkfs.btrfs -L arch /dev/mapper/vg-arch
    # mkswap -L swap /dev/mapper/vg-swap
    ```

##### BTRFS
*B-tree FS*

  - Mount btrfs volume and cd into it:

    ```
    # mount /dev/mapper/vg-arch /mnt && cd /mnt
    ```

  - Add subvolumes:

    ```
    # btrfs subvolume create @
    # btrfs subvolume create @home
    ```

  - Unmount:

    ```
    # cd && umount /mnt
    ```

Now we're going to mount these subvolumes, with compression with lzo and autodefragmentation enabled.

```
# mount /dev/mapper/vg-arch /mnt -o subvol=@,compress=lzo,autodefrag
# mkdir -p /mnt/{home,boot/efi}
# mount /dev/mapper/vg-arch /mnt/home -o subvol=@home,compress=lzo,autodefrag
# mount /dev/mapper/cryptboot /mnt/boot
# mount /dev/sda2 /mnt/boot/efi
# swapon /dev/mapper/vg-swap
```

For SSDs add the `-d` param (discard) to swapon and `discard,ssd` to btrfs subvolumes.
**Again consider droping the TRIM (discard) options.**

```
# mount /dev/mapper/vg-arch /mnt -o subvol=@,discard,ssd,compress=lzo,autodefrag
# mkdir -p /mnt/{home,bootefi}
# mount /dev/mapper/vg-arch /mnt/home -o subvol=@home,discard,ssd,compress=lzo,autodefrag
# mount /dev/mapper/cryptboot /mnt/boot
# mount /dev/sda2 /mnt/boot/efi
# swapon -d /dev/mapper/vg-swap
```
#### Installing Arch Linux
##### Install rootfs with pacstrap
From the live CD we're now going to install Arch to our mounted rootfs:
```
# pacstrap -i /mnt base base-devel intel-ucode bash-completion vim zsh openssl
```

`intel-ucode` is only needed if you're using an intel cpu, more info here
https://wiki.archlinux.org/index.php/Microcode
##### Generate fstab

```
# genfstab -U -p /mnt >> /mnt/etc/fstab
```

You can change `defaults` to `defaults,discard` for swap partition entry in fstab.

```
# nano /mnt/etc/fstab
```

##### Chroot into the new system

```
# arch-chroot /mnt
```

##### Create keyfile for the LUKS partition

While GRUB asks for a passphrase to unlock the encrypted /boot,
the partition unlock is not passed on to the initramfs.
Hence, /boot will not be available after the system has re-/booted,
because the encrypt hook only unlocks the system's root.
We're going to create a keyfile for our LUKS partition so that we won't need to
enter the decryption phrase a 2nd time after GRUB unlocked the partition.
Generate 4096 bit key and add it to LUKS:

```
# dd bs=512 count=8 if=/dev/urandom of=/crypto_keyfile.bin
# cryptsetup luksAddKey /dev/sda3 /crypto_keyfile.bin
```

now we're going to add this file to `/etc/crypttab`:
```
#/etc/crypttab
cryptboot  /dev/sda3      /crypto_keyfile.bin        luks
```

##### Configuring mkinitcpio

- Add crc32c (or crc32c-intel for Intel machines) to the `MODULES` array

```
MODULES=(crc32c-intel)
```

 - Add `btrfs` to the end and `encrypt` and `resume` between `keyboard` and `filesystems` in the `HOOKS` array.

```
HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 resume filesystems fsck btrfs)

```

 - Add the keyfile for the LUKS partition to the initfamfs

```
FILES=(/crypto_keyfile.bin)
```

Install btrfs-progs to use the btrfs hook:

```
# pacman -S btrfs-progs
```

###### Generate initramfs:

```
# mkinitcpio -p linux
```

##### Configuring the boot loader

  - Install the package:
    ```
    # pacman -S grub efibootmgr efitools
    ```

  - Add `GRUB_ENABLE_CRYPTODISK=y` to `/etc/default/grub`
  - Set cryptdevice and resume partition
    - For a HDD:
    ```
    GRUB_CMDLINE_LINUX="cryptdevice=/dev/sda4:lvm resume=/dev/mapper/vg-swap"
    ```
    - For a SSD:
    ```
    GRUB_CMDLINE_LINUX="cryptdevice=/dev/sda4:lvm:allow-discards resume=/dev/mapper/vg-swap"
    ```
  - Generate GRUB's configuration file:
  ```
  # grub-mkconfig -o /boot/grub/grub.cfg
  ```
  - Install GRUB to harddrive:
    - Install GRUB to the mounted ESP for UEFI booting:
    ```
    # grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
    ```
    - Install GRUB to the disk for BIOS booting:
    ```
    # grub-install --target=i386-pc --recheck /dev/sda
    ```

#####  Seting up the base system
* Configure /etc/pacman.conf
  We're going to add GRUB to the ignore list since we're going to always manually update grub with cryptboot,
  so that our bootloader is always signed.
  - change
    ```
    #IgnorePkg    =
    ```
  - to
    ```
    IgnorePkg    = grub
    ```

  Also add **archlinuxfr** to your repositories so that we can install yaourt
  to easily get access to the AUR *Arch User Repository*,
  since we're going to need that to install cryptboot later
  add this to your `/etc/pacman.conf`
  ```
  [archlinuxfr]
  SigLevel = Never
  Server = http://repo.archlinux.fr/$arch
  ```

* Edit /etc/locale.conf:

  ```
  LANG=en_US.UTF-8
  ```

* Edit /etc/locale.gen and uncomment the needed locales:

  ```
  de_DE.UTF-8 UTF-8
  [..]
  en_GB.UTF-8 UTF-8
  [..]
  en_US.UTF-8 UTF-8
  ```

* Generate locales

  ```
  # locale-gen
  ```

* Edit /etc/vconsole.conf and set keymap and font:

  ```
  KEYMAP=de-latin1-nodeadkeys
  FONT=lat9w-16
  ```

* Set timezone:

  ```
  # ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
  ```

* Set hostname:

  ```
  # echo navi > /etc/hostname
  ```
* Create a user:

  Add a user and set the password:

  ```
  # useradd -m -g users -G wheel -s /bin/bash bob
  # passwd bob
  ```
  Run:

  ```
  # visudo
  ```

  and uncomment `%wheel ALL=(ALL:ALL) ALL` or `%wheel ALL=(ALL:ALL) NOPASSWD: ALL`
  if you don't want to enter your password again when using sudo.

  Now remove the root password so that root cannot login
  (don't lock the account with `passwd -l` because than the recovery root login doesn't work anymore):

  ```
  # passwd -d root
  ```

#### Secure Boot
##### Exit Chroot

Now we're going to exit the chroot environment unmount our devices and reboot into our
freshly installed Arch Linux.

  - Umounting devices:
  ```
  # exit
  # umount -R /mnt
  # swapoff /dev/mapper/vg-swap
  ```

  - Reboot:
  ```
  # reboot
  ```
##### Installing Cryptboot
Now we're going to **exactly** follow:

https://github.com/xmikos/cryptboot/blob/master/README.md
Please read through this README and make sure you understand the limitations.

- Since we have yaourt installed we can now easily install sbsigntools and cryptboot:
  ```
  yaourt -S sbsigntools cryptboot
  ```

- Boot into UEFI firmware setup utility (frequently but incorrectly referred to as "BIOS"),
  enable *Secure Boot* and clear all preloaded Secure Boot keys (Microsoft and OEM).
  By clearing all Secure Boot keys, you will enter into *Setup Mode*
  (so you can enroll your own Secure Boot keys later).

  You must also set your UEFI firmware *supervisor password*, so nobody
  can simply boot into UEFI setup utility and turn off Secure Boot.

- Boot into your Linux distribution and mount `/boot` partition and EFI System partition:

        cryptboot mount

- Generate your new UEFI Secure Boot keys:

        cryptboot-efikeys create

- Enroll your newly generated UEFI Secure Boot keys into UEFI firmware:

        cryptboot-efikeys enroll

- Update GRUB boot loader (it will be automatically signed with your new UEFI Secure Boot keys):

        cryptboot update-grub

- Unmount `/boot` partition and EFI System partition:

        cryptboot umount

- Reboot your system, you should be completely secured against evil maid attacks from now on!

**Now whenever you want to update GRUB execute:**
```
cryptboot upgrade
```

This will mount /boot partition and EFI System partition,
properly upgrade your system with distributions package manager,
update and sign GRUB boot loader and finally unmount /boot partition and EFI System partition.

### User Setup
If you managed to boot your system and login to your user account, **CONGRATULATIONS!!!** you now have a fully running arch setup.

In the following steps I will explain how my user account is setup, what software I like to use and how I backup my system with Btrfs.
