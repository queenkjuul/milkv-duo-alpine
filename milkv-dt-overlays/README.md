# Milk-V Duo S Device Tree Overlay Examples

Using the kernel and bootloader from this repo enables device tree overlays through U-Boot. This allows you to modify the device tree at boot time. The advantage of this is that you can configure your available hardware in different ways without having to completely rewrite the baseline device tree provided by the kernel.

The device trees as patched in this repo are pretty maximalist: they enable all of the supported hardware, even though it's not necessarily possible to use all of it simultaneously due to some devices sharing pins. You can use device tree overlays to disable the peripherals you do not plan to use.

Additionally, the partial Arduino support supplied by this repo will not work properly when certain devices that Arduino expects to operate are claimed by the Linux kernel. These changes are automatically applied if the `milkv-arduino` package is installed, otherwise see the `*arduino*.dts` files in this directory for source code.

## The `dtbo` tool

I have provided a simple script for compiling/installing/removing device tree overlays. For example, to build and enable the default built-in LED:

  ```sh
  dtbo install leds.dts
  ```

Reboot and your blue onboard LED should flash with the "heartbeat" trigger, where it increases in frequency proportionally to system load.

Run `dtbo help` for more information.

## Manually Compiling

`dtc -@ -I dts -O dtb -o /boot/dtbo/overlay.dtb /path/to/source.dts`

Then `/etc/default/u-boot` needs to be modified to enable them:

```
U_BOOT_FDT_OVERLAYS="<overlay.dtb> <another_overlay.dtb> ..."
U_BOOT_FDT_OVERLAYS_DIR="/boot/dtbo/"
```

## Examples

- `leds.dts`: Example overlay for setting up LED device nodes for Duo built-in LEDs
- `spi*-spidev0-dh2228fv.dts`: generic SPI device, use for loopback tests or for enabling a generic `/dev/spiX.Y` device to interact with from Linux.
- `duo256m/uart*.dts`: compile and install these to re-enable UART1 and UART3 on the Linux side (by default, they are assigned to Arduino, where they don't currently work)
- `duos/spi3-display0-st7789.dts`: Example overlay for using the Adafruit MiniPiTFT LCD display with the Duo S over SPI. Can be easily modified to work with other Duo boards.