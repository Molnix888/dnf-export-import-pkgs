# dnf-export-import-pkgs

A script created to ease a process of restoring the same set of packages after
system re-installation or for moving it to another system.

It uses package names and ignores versions during operations.
It is recommended for import operation to use files exported via this script.

**Requires root privileges to run.**

## Use

    $ sudo ./dnf-export-import-pkgs.sh
    Usage: sudo ./dnf-export-import-pkgs.sh [-o <export|import>] [-p <arg...>]

    -o  Operation to perform, can either be export or import:
            export - Exports names of installed packages (without version and architecture) to a plain text file.
            import - Imports package names from plain text file and installs the same set of packages removing the ones not in the list.

    -p  Relative filepath, file shouldn't exist for export operation and should exist, be readable and not empty for import operation.
