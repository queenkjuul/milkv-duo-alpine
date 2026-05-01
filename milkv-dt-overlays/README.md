# Milk-V Duo S Device Tree Overlay Examples

Using the kernel and bootloader from this repo enables device tree overlays through U-Boot. This allows you to modify the device tree at boot time. The advantage of this is that you can configure your available hardware in different ways without having to completely rewrite the baseline device tree provided by the kernel.

The device trees as patched in this repo are pretty maximalist: they enable all of the supported hardware, even though it's not necessarily possible to use all of it simultaneously due to some devices sharing pins. You can use device tree overlays to disable the peripherals you do not plan to use, and to mux the pins as necessary for the devices you do want to use.

Additionally, the partial Arduino support supplied by this repo will not work properly when certain devices that Arduino expects to operate are claimed by the Linux kernel. These changes are automatically applied if the `milkv-arduino` package is installed, otherwise see the `*arduino*.dts` files in this directory for source code.

Included in this package is some of the pinctrl driver source code from the Linux source tree, modified so that the pinmux identifiers match the Milk-V diagrams - so instead of a kernel symbol like `PIN_MIPIRX1N`, you can just use `GP10` in your pinmux declarations. See the `spi2-fb0-st7789v-duo256m.dts` file for examples. All of the complete mappings can be found in the files under `include/`.

## The `dtbo` tool

I have provided a simple script for compiling/installing/removing device tree overlays. For example, to build and enable the default built-in LED:

  ```sh
  dtbo install leds.dts
  ```

Reboot and your blue onboard LED should flash with the "heartbeat" trigger, where it increases in frequency proportionally to system load.

**NOTE:** Due to wiring differences on the Duo 256M, its built-in LED is not able to be activated via the device tree. If you really want it to blink, I suggest using [Arduino](../sophgo-arduino/README.md) as that bypasses the kernel.

Run `dtbo help` for more information.

## Manually Compiling

`cpp -nostdinc -I/usr/src/dt-overlays/include -undef -x assembler-with-cpp my-overlay.dts | dtc -@ -I dts -O dtb -o /boot/dtbo/my-overlay.dtb -`

Then `/etc/default/u-boot` needs to be modified to enable them:

```
U_BOOT_FDT_OVERLAYS="<my-overlay.dtb> <another_overlay.dtb> ..."
U_BOOT_FDT_OVERLAYS_DIR="/boot/dtbo/"
```

then run `u-boot-update` to apply.

## Examples

- `leds.dts`: Example overlay for setting up LED device nodes for Duo built-in LEDs
- `spi*-spidev0-dh2228fv.dts`: generic SPI device, use for loopback tests or for enabling a generic `/dev/spiX.Y` device to interact with from Linux.
- `spi*-fb0-st7789-*.dts`: Example overlay for using the Adafruit MiniPiTFT LCD display over SPI. Can be easily modified to work with other Duo boards or different pin assignments.