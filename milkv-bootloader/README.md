# `milkv-bootloader`

Patches for `duo-buildroot-sdk-v2` to enable Distroboot on SG2000 boards. Right now, only the Milk-V Duo S is supported, but the other Duo boards are on the way.

## Contents

- `*.patch`: patch files to apply to `duo-buildroot-sdk-v2` before running `build_fsbl` (apply with `git am <patch>`; see Milk-V buildroot "step by step compilation" instructions for how to run `build_fsbl` for `milkv_duo_s_musl_sd` or `milkv_duo256m_musl_sd`)
- `fip.bin`: pre-built distroboot image for Milk-V Duo S, assumes that `mmcblk0p3` is the root partition and is marked `bootable`; while `mmcblk0p1` contains `fip.bin` and `boot.sd` (as a fallback for distroboot)
