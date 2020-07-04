# dnf-export-import-pkgs

A script created to ease the process of restoring exactly the same set of packages after system re-installation or allowing to move it to another system.

It uses only the package names and completely ignores the versions during operations.

**Requires root privileges to run.**

    Usage: sudo ./dnf-export-import-pkgs.sh -o option
        -o Option of script usage. It can either be 'export' or 'import'.
