# Ubuntu on the Milk-V Duo S RISC-V
Full-featured, general-purpose Ubuntu 22.04 distribution for Milk-V Duo S SBCs, built on the latest 7.0 Linux kernel.

<img width="1280" height="836" alt="image" src="https://github.com/user-attachments/assets/6a2d1765-dc41-4cb2-b000-97cf976d3f32" />

*For now, this is __ONLY__ for the Duo S, but the Duo 256M is planned. Duo 64M is not supported*
*(I have ordered myself a Duo 64M, though, so I might still port the kernel work over)*

## What it is

This will be a monorepo set up with submodules to pull in:

- Linux 7.0 with all necessary Milk-V Duo S patches
- Scripts for cross-building .deb packages:
  - Linux 7.0
  - Wireless drivers
  - Userspace scripts for setting USB operating mode
  - Userspace scripts for setting up wireless hardware
  - Prebuilt vendor bootloader image and applicable patches
  - Milk-V `duo-pinmux` tool
  - [`genimage` for building the SD image](https://github.com/pengutronix/genimage)
  - [bluetui](https://github.com/pythops/bluetui) and [impala](https://github.com/pythops/impala) for managing wireless hardware
- Scripts for generating an Ubuntu 22.04 userspace rootfs

Packages are hosted on Ubuntu PPA:

- https://launchpad.net/~queenkjuul/+archive/ubuntu/milkv-duos

## Features

- 3 USB modes, selectable via systemd service:
  - USB Host: Use the USB A port to access peripheral devices
  - USB Serial (ACM): Connect to a PC with USB-C and log in over serial
  - USB Network (CDC-NCM) [formerly RNDIS]: Connect to a PC with USB-C and log in over SSH or otherwise access via network protocols
- Modern Linux 7.0 mainline kernel (with minor device tree and driver patches)
- Modern Ubuntu 22.04 userspace
- Full USB Gadget support
- Full USB Host support
- Support for Duo S Ethernet
- Working Wifi (at least 2.4GHz, 5GHz untested)
- Working Bluetooth
- I2S Audio driver (untested)
- Automatic root partition expansion on first boot

## Missing Features

- ~~Wifi (not mainlined, investigating vendor drivers)~~ nah bb wifi works now :sunglasses:
- ~~Bluetooth~~ (same as wifi) :sunglasses:
- ~~Software reboot (system hangs waiting for hardware reset button)~~ nah we got this now :)
- U-Boot 2026.1 (system depends on vendor-supplied first stage bootloader (FSBL) which uses U-Boot 2021.10)
- MIPI / CSI (Camera interface)
- TPU support
- Multimedia support (VIP)

## Goals

This is not your typical embedded distribution. Because the Duo S features full-size Ethernet and USB-A ports, in addition to all the typical embedded I/O, the kernel build for this distro features dozens, if not hundreds, of device drivers (built as modules): Game controllers, MIDI devices, HID, serial, printers, modems, sensors, most anything you can think of.

The idea is that if you have a USB-A port, you oughtta be able to use it. The Duo S isn't really powerful enough to be a desktop, but I can envision some fun ways to incorporate it as a Linux Gadget or a mini server or a media player or whatever. I also want this to be a good entrypoint for beginners, because this board has a lot of potential.

You can always reconfigure the kernel to remove what you don't want. The actual kernel without any modules loaded is 9MB,

The Milk-V SDK usage patterns are in some places replicated (hardware state is largely managed by shell scripts, USB NCM mode is the default) but the specific instructions are different. 

### Kernel Methodology

As much as possible is "upstream"/"mainline". Some of the patches applied are likely to be pulled into Linux 7.0 (and some listed on the wiki as unmerged, like audio, have actually been pulled already) and a few I made myself. Wifi drivers are hacky and a little bit vibed but they work so ¯\_(ツ)_/¯

1. Started with basline Linux 7.0-rc3 (and plan to rebase on future rcs, up to 7.0)
2. Added LKML patches linked from [the Sophgo Linux Wiki](https://github.com/sophgo/linux/wiki)
3. Added my own patches to the device tree:
  4. Fix device tree after applying upstream mdio-mux driver patch
  5. Enable USB OTG in Milk-V Duo S device tree
  6. Add watchdog timer device tree node (upstream watchdog patch doesn't apply cleanly)
  7. Enable watchdog timer device node in Milk-V Duo S device tree
  8. Enable `uart4` for `hci_uart` in Milk-V Duo S device tree

## Using the System

In general, [this portion of the Milk-V docs also applies to this distribution](https://milkv.io/docs/duo/getting-started/setup) except for a couple things:

- [Setting the USB gadget IP address is different](#changing-the-usb-gadget-ip-address)
- My build scripts automatically expand the root partition on first boot

### Default Password
`root` / `milkv`

### First Boot
The first boot can take ~2 minutes as the system generates SSH keys and expands the root partition to the full size of the SD card. Subsequent boots will be much faster.

### USB

USB drivers are built into the kernel. The `milkv-usb-duos` package contains userspace scripts for switching modes and a systemd unit for setting modes at boot time.

The system is set up for USB CDC NCM by default. This is the modern equivalent of RNDIS; it configures the board as a "USB Ethernet Gadget" and allows you to talk to the board via SSH over USB:

`ssh root@192.168.42.1`

This is the same as the Milk-V default, so you [can use their docs to get set up](https://milkv.io/docs/duo/getting-started/setup), [except for changing the USB IP](#changing-the-usb-gadget-ip-address).

You can switch to Host Mode (USB-A) with:

`milkv-usb-mode host` and then reboot. There are systemd services that handle the initialization. If you disable those, use `milkv-usb-init` to set things up after boot.

### Pin Configuration

`duo-pinmux`, as provided by Milk-V, is also included in the system image. You can use it to reconfigure pins - all of the Duo S's hardware is exposed to the kernel via the device tree, but some of it may not work until you set the pins correctly. For example, to use `I2C4` via pins `B20` and `B21`, you must set pins `B20` and `B21` appropriately with `duo-pinmux`. After that, the `/dev/i2c-*` devices will work (you may need to `modprobe i2c-dev` first). Note that just because the `/dev/*` node appears, doesn't mean it works - you need to set the pins correctly. Only `/dev/ttyS0` (the boot console) and `/dev/ttyS4` (the bluetooth UART) are guaranteed to work at boot.

Refer to the pinout chart below - the labels don't map 1:1 with the actual command options - use `duo-pinmux -l` for all of the valid options

![](https://milkv.io/duo-s/duos-pinout.webp)

#### Changing the USB gadget IP address

**Note that these instructions differ from the Milk-V docs**

You can edit `/etc/netplan/90-usb-gadget.yaml` to set the IP. You should keep the `/24` unless you know what you're doing. The USB gadget gets the fist IP (`192.168.42.1`) and each client (so likely just the one host PC) will get the next (`192.168.42.2`).

```yaml
      addresses:
        - 192.168.42.1/24
```

### WiFi + BT

There are 5 packages relevant to wireless on the Duo S:

- `milkv-wireless-duos`: Userspace scripts and systemd units to enable wireless hardware (technically optional)
- `aic8800-milkv-firmware`: Vendor firmware binary blobs (required)
- `aic8800-milkv-modules-duos`: Kernel modules for the `linux-image-milkv-duos_7.0~rc4-qkj1` kernel (default kernel for this setup) (required)
- [`extras/impala`](https://github.com/pythops/impala): an easy-to-use TUI for setting up WiFi connections (optional, third-party)
- [`extras/bluetui`](https://github.com/pythops/bluetui): an easy-to-use TUI for setting up Bluetooth connections (optional, third-party)

All but the `extras/` packages are installed by default. Wifi and Bluetooth are both enabled by default. Disable one or the other with:

```sh
systemctl disable milkv-wifi
systemctl disable milkv-bluetooth
```

#### Usage

The base system installs `iwd` for WiFi management. A nice helper script is provided, `milkv-wifi-setup`, which you can use to connect to a network. `milkv-wifi-setup` also offers the option to apply your WiFi settings at boot, and if chosen, will persist the WiFi MAC address as well (this is normally randomly generated at each boot). 

The repo also provides the `impala` and `bluetui` packages for friendly wireless management over SSH connections.

My personal recommendation is to use `milkv-wifi-setup` initially, as it works well in a serial terminal and sets up the `iwd` daemon and WiFi MAC address. Then, once you're connected to WiFi and logged in over SSH, switch to `impala` - it's much more versatile, it looks nicer, and it's just as easy to use.

#### Power

Note that since both Bluetooth and Wifi are on the same chip and use the same driver, both will be enabled at the hardware level when either script is enabled. The difference is that the Bluetooth service starts an `hciattach` session as a daemon and loads the `bluetooth` module, the WiFi service does not. Disable both services (or prevent loading the `aic8800_bsp` driver) to keep the wireless chip powered off.

#### Boot Warnings

There are some false alarm errors on boot when using the wireless chip, but they don't affect operation. Here's a normal, working boot log:

```
[   22.026658] mmc1: tuning execution failed: -110
[   22.026691] mmc1: error -110 whilst initialising SDIO card
[   23.562645] aicbsp: Device init failed, powering down
[   32.314462] aicbsp: sdio_err:<aicwf_sdio_bus_pwrctl,1498>: bus down
[   33.042238] ieee80211 phy0:
[   33.042238] *******************************************************
[   33.042238] ** CAUTION: USING PERMISSIVE CUSTOM REGULATORY RULES **
[   33.042238] *******************************************************
[   35.749812] Bluetooth: hci0: Opcode 0x2003 failed: -110
```

Despite all of these dmesg errors, this boot did produce a working Wifi+BT system. Don't be fooled.

### Bootloader

The system is set up with `/boot` on the root ext4 filesystem (`mmcblk0p3`), and `mmcblk0p1` mounted to `/boot/vendor`. 

`/boot/vendor` contains two files:

- `fip.bin`: vendor-supplied bootloader, modified for "distroboot" - this loads a simple boot menu listing installed kernels, and loads everything it needs from the root ext4 filesystem
- `boot.sd`: this is a "FIT image" which contains an embedded kernel and device tree. This is provided as a failsafe - you can press a key to interrupt auto-boot then from the U-Boot prompt run `run sdboot` to use the FIT image instead of the "distroboot" menu.

U-Boot supports the ethernet port, and distroboot supports network booting, and it does appear to work (ethernet initializes, and it fetches an address from DHCP, and it attempts to fetch a file from TFTP, but I don't have TFTP set up to test further).

#### Kernel Upgrades

When the SD card is generated, a `boot.sd` is generated from the kernel in the image, and installed to `/boot/vendor`. Kernel upgrades installed via APT will generate new `boot.sd` images, stored at `/boot/boot.sd-$KERNELVERSION` - they are not automatically installed to `/boot/vendor` (`mmcblk0p1`) - after you have confirmed that the new kernel works correctly by booting it, you can replace the old `/boot/vendor/boot.sd` with the new one. Because `boot.sd` is provided primarily as a failsafe should "distroboot" fail, the previous known-good `boot.sd` is left in place until you manually replace it.

## Notes

- While USB-C Serial is available, it doesn't initialize until late in the boot process, and does not display the kernel console. You will need to use the UART0 pins and connect to an adapter to troubleshoot boot problems.
- Board has soft-reset but not soft-poweroff. `systemctl poweroff` will halt the system, but it remains powered as long as power is supplied.

## Building the System

### Basic - Default Settings

*For now, building the SD card image is only supported on Ubuntu 22.04 hosts on the amd64 platform. A Dockerfile is in progress. It may work on other Debian-based distros but this isn't tested.*

`git clone https://github.com/queenkjuul/ubuntu-milkv-duo`

An automatic build process can be initiated with `build.sh`, it will prompt for basic settings (hostname, root password). It will install pre-built packages from my PPA.

### Advanced - Building Yourself

**THESE INSTRUCTIONS ARE CURRENTLY INCOMPLETE AND CURRENTLY DO NOT WORK**

`git clone --recursive https://github.com/queenkjuul/ubuntu-milkv-duo`

Your best bet is a fresh Ubuntu 22.04 VM (the scripts assume you're running 22.04).

You can adjust and rebuild any of the constituent packages. The build script will install any `*.deb` packages within the root directory. So you can go into any submodule (e.g. `milkv-linux`, `milkv-wireless-duos`, etc.) and build a new debian package (I was using `debuild`) which will be installed in the target system. Obviously any pre-built packages you want to include can also be added by just placing them in the project root (`ubuntu-milkv-duo/my-package.deb`) and running the build script.

**DON'T RUN THE SETUP SCRIPT ON YOUR REAL HOST! USE A VM! IT WILL MANGLE YOUR APT SOURCES.LIST!**

The setup script must be run as root, because it installs dependencies using `apt`:

`sudo ./setup.sh`

Run the build script with:

`./build.sh`

#### Build Sequence

The `aic8800-modules-*` packages require the relevant kernel headers (`linux-headers-milkv-duos`) to be installed on the build system in order to build. Therefore, it is recommended to build the kernel packages first, then the drivers, then everything else:

1. `debuild -S -sa -us -uc` - builds the source package
2. `debuild -ariscv64 -b -us -uc` - builds the binary package

(the `-us` and `-uc` and `-sa` options are for disabling signatures - you'd need to omit those flags if you were actually publishing to a PPA)

Following the general order of `kernel -> install generated headers package -> build modules -> build everything else` should get you up and running.

When you run `debuild` within one of the modules, the output will be placed in the repo root directory. When you run `./build.sh`, all `*.deb` files in the root directory will be installed automatically - just make sure all the ones you want are built ahead of time.

#### Customization

You can add packages to the `PACKAGES` list in `second-stage.sh`.

Basic system configuration is handled in `second-stage.sh`


===
[Below this line is old documentation, likely outdated, updates coming]
===

## Credits
By far the most useful reference reference was [Fishwaldo's `sophgo-sg200x-debian` project](https://github.com/Fishwaldo/sophgo-sg200x-debian). This was pretty invaluable.

Everything below this line is from the original README.md of the repo I forked ([credit to ambraglow too, of course](https://github.com/ambraglow/milkv-duo-ubuntu)), so I don't give it my personal approval, but I will leave it here for visibility. The old instructions below will likely be removed, though; my scripts are only loosely similar.

![great friend julie](https://github.com/tvlad1234) _[different julie :)]_
![rootfs guide for risc-v](https://github.com/carlosedp/riscv-bringup/blob/master/Ubuntu-Rootfs-Guide.md)
![DO NOT THE CAT!!!](https://github.com/Mnux9)

## Setup 
1. Ubuntu 22.04 LTS installed on a virtual machine
2. Setup ![duo-buildroot-sdk](https://github.com/milkv-duo/duo-buildroot-sdk#prepare-the-compilation-environment) on your machine

## Before anything else
```bash
# We need to enable a few modules in the kernel configuration before we can continue, so:
nano ~/duo-buildroot-sdk/build/boards/cv180x/cv1800b_milkv_duo_sd/linux/cvitek_cv1800b_milkv_duo_sd_defconfig

# and add at the end:
CONFIG_CGROUPS=y
CONFIG_CGROUP_FREEZER=y
CONFIG_CGROUP_PIDS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CPUSETS=y
CONFIG_PROC_PID_CPUSET=y
CONFIG_CGROUP_CPUACCT=y
CONFIG_PAGE_COUNTER=y
CONFIG_MEMCG=y
CONFIG_CGROUP_SCHED=y
CONFIG_NAMESPACES=y
CONFIG_OVERLAY_FS=y
CONFIG_AUTOFS4_FS=y
CONFIG_SIGNALFD=y
CONFIG_TIMERFD=y
CONFIG_EPOLL=y
CONFIG_IPV6=y
CONFIG_FANOTIFY

# optional (enable zram):
CONFIG_ZSMALLOC=y
CONFIG_ZRAM=y
```
Important: to reduce ram usage follow point n.2 of the ![faq](https://github.com/milkv-duo/duo-buildroot-sdk/tree/develop#faqs), 
to increase the rootfs partition size you can edit ```duo-buildroot-sdk/milkv/genimage-milkv-duo.cfg```
at line 16 replace ```size = 256M``` with ```size = 1G``` or higher as desired
then follow the ![instructions](https://github.com/milkv-duo/duo-buildroot-sdk#step-by-step-compilation) to manually compile buildroot and the kernel and pack it. 

## Creating the rootfs
```bash
# install prerequisites
sudo apt install debootstrap qemu qemu-user-static binfmt-support dpkg-cross --no-install-recommends
# generate minimal bootstrap rootfs
sudo debootstrap --arch=riscv64 --foreign jammy ./temp-rootfs http://ports.ubuntu.com/ubuntu-ports
# chroot into the rootfs we just created
sudo chroot temp-rootfs /bin/bash
# run 2nd stage of deboostrap
/debootstrap/debootstrap --second-stage
# add package sources
cat >/etc/apt/sources.list <<EOF
deb http://ports.ubuntu.com/ubuntu-ports jammy main restricted

deb http://ports.ubuntu.com/ubuntu-ports jammy-updates main restricted

deb http://ports.ubuntu.com/ubuntu-ports jammy universe
deb http://ports.ubuntu.com/ubuntu-ports jammy-updates universe

deb http://ports.ubuntu.com/ubuntu-ports jammy multiverse
deb http://ports.ubuntu.com/ubuntu-ports jammy-updates multiverse

deb http://ports.ubuntu.com/ubuntu-ports jammy-backports main restricted universe multiverse

deb http://ports.ubuntu.com/ubuntu-ports jammy-security main restricted
deb http://ports.ubuntu.com/ubuntu-ports jammy-security universe
deb http://ports.ubuntu.com/ubuntu-ports jammy-security multiverse
EOF
# update and install some packages
apt-get update
apt-get install --no-install-recommends -y util-linux haveged openssh-server systemd kmod initramfs-tools conntrack ebtables ethtool iproute2 iptables mount socat ifupdown iputils-ping vim dhcpcd5 neofetch sudo chrony
# optional for zram
apt-get install zram-config
systemctl enable zram-config
# Create base config files
mkdir -p /etc/network
cat >>/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

cat >/etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

# write text to fstab (this is with swap enabled if you want to disable it just put a # before the swap line)
cat >/etc/fstab <<EOF
# <file system>	<mount pt>	<type>	<options>	<dump>	<pass>
/dev/root	/		ext2	rw,noauto	0	1
proc		/proc		proc	defaults	0	0
devpts		/dev/pts	devpts	defaults,gid=5,mode=620,ptmxmode=0666	0	0
tmpfs		/dev/shm	tmpfs	mode=0777	0	0
tmpfs		/tmp		tmpfs	mode=1777	0	0
tmpfs		/run		tmpfs	mode=0755,nosuid,nodev,size=64M	0	0
sysfs		/sys		sysfs	defaults	0	0
/dev/mmcblk0p3  none            swap    sw              0       0
EOF
# set hostname
echo "milkvduo-ubuntu" > /etc/hostname
# set root passwd
echo "root:riscv" | chpasswd
# enable root login through ssh
sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
# exit chroot
exit
sudo tar -cSf Ubuntu-jammy-rootfs.tar -C temp-rootfs .
gzip Ubuntu-jammy-rootfs.tar
rm -rf temp-rootfs

```
## Flashing
next up, we flash the image on the sd card like so:
```bash
dd if=milkv-duo.img of=/dev/sdX status=progress #replace X with your device name
```
we mount the rootfs partition and we delete all the files inside with ```bash sudo rm -r /media/yourusername/rootfs``` 
then create a directory ```mkdir ubunturootfs``` to extract our ```Ubuntu-jammy-rootfs.tar``` and run 
```bash
tar -xf Ubuntu-jammy-rootfs.tar -C ubunturootfs
```
now we copy the rootfs to our mounted partition:
```bash
sudo cp -r ubunturootfs/* /media/yournamehere/rootfs/
```
and that's all! you should now be able to boot into ubuntu no problem
