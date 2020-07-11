#!/bin/bash

installedPkgsToFileFunction () {
    if [ -f "$1" ]
    then
        echo "File $1 already exists."
        exit 1
    else
        dnf repoquery --installed | sort | grep -oP "(^.+)(?=-[\d]+:.+)" | uniq -i > $1 && echo "Package list successfully exported to $1." || echo "Error occured during export operation."
    fi
}

helpFunction () {
    echo "Usage: sudo $0 -o option
    -o Option of script usage. It can either be 'export' or 'import'.
        export - Exports currently installed package names list (without versions and architecture) to plain text file.
        import - Imports package names list from plain text file and installs exactly the same package set removing the ones not in provided list."

    exit 1
}

exportFunction () {
    echo "Specify filename for package list (without extension):"

    read name

    if [ -z "$name" ]
    then
        echo "Empty filename provided."
    else
        installedPkgsToFileFunction "$name.txt"
    fi

    exit 1
}

importFunction () {
    echo "Specify path to file with package list to restore:"

    read expected

    if [[ -f "$expected" && -r "$expected" && -s "$expected" ]]
    then
        actual=$(uuidgen).txt
        installedPkgsToFileFunction $actual

        # Comparing pkg lists and returning only the lines absent in expected list
        toDelete=$(grep -Fxvf $expected $actual)

        dnf remove $toDelete

        dnf install $(cat $expected)

        rm $actual && echo "$actual file successfully deleted." || echo "Can't delete $actual file."
    else
        echo "Provided file either not exists, not readable or is empty."
    fi

    exit 1
}

[[ $EUID -ne 0 ]] && echo "Script requires root privileges." && exit 1

while getopts "o:" opt
do
    case "$opt" in
        o ) option="$OPTARG";;
        ? ) helpFunction;;
    esac
done

if [ -z "$option" ]
then
    echo "No parameters provided."
    helpFunction
elif [ "$option" = "export" ]
then
    exportFunction
elif [ "$option" = "import" ]
then
    importFunction
else
    echo "Invalid parameter value provided."
    helpFunction
fi
