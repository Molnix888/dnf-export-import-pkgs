#!/bin/bash

installedPkgsToFileFunction() {
    if [ -f "$1" ]; then
        echo "File $1 already exists." && exit 1
    else
        dnf repoquery --installed | sort | grep -oP "(^.+)(?=-[\d]+:.+)" | uniq -i > "$1" && echo "Package list successfully exported to $1." || ( echo "Error occurred during export operation." && exit 1 )
    fi
}

helpFunction() {
    echo "Usage: sudo $0 [-o <export|import>]

Arguments:
    export - Exports names of installed packages (without version and architecture) to a plain text file.
    import - Imports package names from plain text file and installs the same set of packages removing the ones not in the list."

    exit 1
}

exportFunction() {
    read -p "Specify filename for package list (without extension): " name

    if [ -z "$name" ]; then
        echo "Empty filename provided." && exit 1
    else
        installedPkgsToFileFunction "$name.txt"
    fi
}

importFunction() {
    read -p "Specify path to file with package list to restore: " expected

    if [ -f "$expected" ] && [ -r "$expected" ] && [ -s "$expected" ]; then
        local actual=$(uuidgen).txt
        installedPkgsToFileFunction "$actual"

        # Comparing pkg lists and returning only the lines absent in expected list
        local toDelete=$(grep -Fxvf "$expected" "$actual")

        dnf remove "$toDelete"

        dnf --setopt=install_weak_deps=False install $(cat "$expected")

        rm "$actual" && echo "$actual file successfully deleted." || ( echo "Can't delete $actual file." && exit 1 )
    else
        echo "File not exists, not readable or is empty." && exit 1
    fi
}

if [ $EUID -ne 0 ]; then
    echo "Script requires root privileges." && exit 1
fi

while getopts "o:" opt; do
    case "$opt" in
        o ) arg="$OPTARG";;
        ? ) helpFunction;;
    esac
done

if [ -z "$arg" ]; then
    helpFunction
elif [ "$arg" = "export" ]; then
    exportFunction
elif [ "$arg" = "import" ]; then
    importFunction
else
    echo "Invalid argument." && helpFunction
fi
