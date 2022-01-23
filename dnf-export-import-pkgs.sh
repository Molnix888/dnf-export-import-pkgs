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
        echo "$1 already exists."
    else
        (dnf repoquery --installed | sort | grep -oP "(^.+)(?=-[\d]+:.+)" | uniq -i >"$1" && echo "Package list successfully exported to $1.") || (echo "Error occurred during exporting to $1." && exit 1)
    fi
}

export_pkgs() {
    if [ -z "$1" ]; then
        echo "Empty filepath."
    else
        pkg_list_to_file "$1"
    fi
}

# Compares 2 files returning lines absent in 1.
get_delta() {
    echo grep -Fxvf "$1" "$2"
}

remove_file() {
    (rm "$1" && echo "$1 successfully deleted.") || (echo "Error occurred during deletion of $1." && exit 1)
}

import_pkgs() {
    if [ -f "$1" ] && [ -r "$1" ] && [ -s "$1" ]; then
        local actual
        actual=$(uuidgen)

        pkg_list_to_file "$actual"

        local to_delete
        to_delete=$(get_delta "$1" "$actual")

        for pkg in $to_delete; do
            dnf remove -y "$pkg"
        done

        remove_file "$actual"
        pkg_list_to_file "$actual"

        local to_install
        to_install=$(get_delta "$actual" "$1")

        for pkg in $to_install; do
            dnf --setopt=install_weak_deps=False install -y "$pkg"
        done

        remove_file "$actual"
    else
        echo "File not exists, not readable or is empty."
    fi
}

if [ $EUID -ne 0 ]; then
    echo "Root privileges required." && exit 1
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
