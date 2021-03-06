#!/bin/bash

get_help() {
    echo "Usage: sudo $0 [-o <export|import>] [-p <arg...>]

-o  Operation to perform, can either be export or import:
        export - Exports names of installed packages (without version and architecture) to a plain text file.
        import - Imports package names from plain text file and installs the same set of packages removing the ones not in the list.

-p  Relative filepath, file shouldn't exist for export operation and should exist, be readable and not empty for import operation."

    exit 1
}

pkg_list_to_file() {
    if [ -f "$1" ]; then
        echo "File $1 already exists." && get_help
    else
        (dnf repoquery --installed | sort | grep -oP "(^.+)(?=-[\d]+:.+)" | uniq -i >"$1" && echo "Package list successfully exported to $1.") || (echo "Error occurred during export operation to $1." && exit 1)
    fi
}

export_pkgs() {
    if [ -z "$1" ]; then
        echo "Empty filepath provided." && get_help
    else
        pkg_list_to_file "$1"
    fi
}

import_pkgs() {
    if [ -f "$1" ] && [ -r "$1" ] && [ -s "$1" ]; then
        local actual
        actual=$(uuidgen)
        pkg_list_to_file "$actual"

        # Comparing pkg lists and returning only the lines absent in received list
        local to_delete
        to_delete=$(grep -Fxvf "$1" "$actual")

        dnf remove "$to_delete"
        dnf --setopt=install_weak_deps=False install "$(cat "$1")"

        (rm "$actual" && echo "$actual file successfully deleted.") || (echo "Error occurred during delete operation of $actual file." && exit 1)
    else
        echo "File not exists, not readable or is empty." && get_help
    fi
}

if [ $EUID -ne 0 ]; then
    echo "Script requires root privileges." && exit 1
fi

while getopts "o:p:" opt; do
    case "$opt" in
    o) operation="$OPTARG" ;;
    p) path="$OPTARG" ;;
    ?) get_help ;;
    esac
done

if [ -z "$operation" ]; then
    get_help
elif [ "$operation" = "export" ]; then
    export_pkgs "$path"
elif [ "$operation" = "import" ]; then
    import_pkgs "$path"
else
    echo "Invalid operation." && get_help
fi
