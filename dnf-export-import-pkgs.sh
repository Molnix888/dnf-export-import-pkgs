#!/bin/bash

installedPkgsToFileFunction() {
    if [ -f "$1" ]; then
        echo "File $1 already exists." && exit 1
    else
        (dnf repoquery --installed | sort | grep -oP "(^.+)(?=-[\d]+:.+)" | uniq -i >"$1" && echo "Package list successfully exported to $1.") || (echo "Error occurred during export operation." && exit 1)
    fi
}

helpFunction() {
    echo "Usage: sudo $0 [-o <export|import>] [-p <arg...>]

-o  Operation to perform, can either be export or import:
        export - Exports names of installed packages (without version and architecture) to a plain text file.
        import - Imports package names from plain text file and installs the same set of packages removing the ones not in the list.

-p  Relative filepath, file shouldn't exist for export operation and should exist, be readable and not empty for import operation."

    exit 1
}

exportFunction() {
    if [ -z "$1" ]; then
        echo "Empty filepath provided." && helpFunction
    else
        installedPkgsToFileFunction "$1"
    fi
}

importFunction() {
    if [ -f "$1" ] && [ -r "$1" ] && [ -s "$1" ]; then
        local actual
        actual=$(uuidgen)
        installedPkgsToFileFunction "$actual"

        # Comparing pkg lists and returning only the lines absent in received list
        local toDelete
        toDelete=$(grep -Fxvf "$1" "$actual")

        dnf remove "$toDelete"
        dnf --setopt=install_weak_deps=False install "$(cat "$1")"

        (rm "$actual" && echo "$actual file successfully deleted.") || (echo "Error occurred during delete operation of $actual file." && exit 1)
    else
        echo "File not exists, not readable or is empty." && helpFunction
    fi
}

if [ $EUID -ne 0 ]; then
    echo "Script requires root privileges." && exit 1
fi

while getopts "o:p:" opt; do
    case "$opt" in
    o) operation="$OPTARG" ;;
    p) path="$OPTARG" ;;
    ?) helpFunction ;;
    esac
done

if [ -z "$operation" ]; then
    helpFunction
elif [ "$operation" = "export" ]; then
    exportFunction "$path"
elif [ "$operation" = "import" ]; then
    importFunction "$path"
else
    echo "Invalid operation." && helpFunction
fi
