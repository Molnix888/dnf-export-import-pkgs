#!/bin/bash

installedListToFileFunction () {
    dnf repoquery --installed | sort > $1 && echo "Package list successfully exported to $1." || echo "An error occured during operation."
}

helpFunction () {
    echo "Usage: sudo $0 -o option
    -o Option of script usage. It can either be 'export' or 'import'."

    exit 1
}

exportFunction () {
    echo "Specify name for package list file (without extension):"

    read filename

    # Verifying if provided input is valid
    if [ -z "$filename" ]
    then
        echo "Empty file name provided."
    else
        installedListToFileFunction "$filename-$(uuidgen).txt"
    fi

    exit 1
}

importFunction () {
    echo "Specify file with package list (with extension):"

    # Declaring variables for list files
    read expected
    actual=$(uuidgen).txt

    # Verifying if expected file exists, is readable and not empty
    if [[ -f "$expected" && -r "$expected" && -s "$expected" ]]
    then
        # Creating actual pkgs list
        installedListToFileFunction $actual

        # Comparing actual list with expected and returning only the diff lines
        diff=$(grep -Fxvf $expected $actual)

        # Removing pkgs from diff list
        dnf remove $diff

        # Installing pkgs from expected list
        dnf install $(cat $expected)

        # Deleting temp actual list file
        rm $actual && echo "$actual file successfully deleted." || echo "Can't delete $actual file."
    else
        echo "Provided file for packages import either not exists, not readable or is empty."
    fi

    exit 1
}

[[ $EUID -ne 0 ]] && echo "The script requires root privileges." && exit 1

while getopts "o:" opt
do
    case "$opt" in
        o ) option="$OPTARG";;
        ? ) helpFunction;;
    esac
done

# Verifying provided option parameter
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
