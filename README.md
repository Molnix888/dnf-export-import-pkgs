# dnf-export-import-pkgs

A script created to ease the process of restoring exactly the same set of packages after system re-installation or allowing to move it to another system.

It uses only the package names and completely ignores the versions during operations. It is strongly recommended to use for import only generated file exported via this script.

**Requires root privileges to run.**

    Usage: sudo ./dnf-export-import-pkgs.sh -o option
        -o Option of script usage. It can either be 'export' or 'import'.
            export - Exports currently installed package names list (without versions and architecture) to plain text file.
            import - Imports package names list from plain text file and installs exactly the same package set removing the ones not in provided list.
