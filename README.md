# dnf-export-import-pkgs

A script created to ease the process of restoring the same set of packages after system re-installation or for moving it to another system.

It uses only the package names and ignores the versions during operations. It is recommended for import operation to use only files exported via this script.

**Requires root privileges to run.**

## Use

    $ sudo ./dnf-export-import-pkgs.sh
    Usage: sudo ./dnf-export-import-pkgs.sh [-o <export|import>]
    
    Arguments:
        export - Exports currently installed package names (without version and architecture) to plain text file.
        import - Imports package names from plain text file and installs exactly the same package set removing the ones not in the list.
