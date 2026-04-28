% milkv-dt-overlays(SECTION) | User Commands
%
% "April 17 2026"

# NAME

dtbo - A tool for managing Device Tree Overlays

# Usage:

  ```sh
  dtbo COMMAND FILE
  ```

# Commands:

  `help`
    You are here

  `install FILE`
    Compiles a provided DTS file into a DTB file,
    places it in /boot/dtbo, and updates U-Boot to
    apply the DTB at boot time

  `compile FILE`
    Compiles the provided DTS file and outputs it
    to the current directory

  `enable FILE`
    Adds the provided DTB file to U-Boot and updates
    U-Boot to apply the DTB at boot time.
    FILE should be the name of a file already placed
    in /boot/dtbo

  `disable FILE`
    Removes the provided DTB file from U-Boot and updates
    U-Boot to prevent applying the DTB at boot time.
    FILE should be the name of a file already placed
    in /boot/dtbo

# Notes:

  Example DTS source files can be found in

    /usr/src/dt-overlays
  
  These examples can be applied via

    dtbo install leds.dts

  and later disabled with

    dtbo disable leds.dtb

  DTS files may need modifying to work with your Duo variant,
  read them before installing them!

# AUTHOR

Julie Hill <queenkjuul@pm.me>
:   Wrote this package.

# COPYRIGHT

Copyright © 2026 Julie Hill

This manual page was written for the Debian system (and may be used by
others).

Permission is granted to copy, distribute and/or modify this document under
the terms of the GNU General Public License, Version 2 or (at your option)
any later version published by the Free Software Foundation.

On Debian systems, the complete text of the GNU General Public License
can be found in /usr/share/common-licenses/GPL.

[comment]: #  Local Variables:
[comment]: #  mode: markdown
[comment]: #  End:
