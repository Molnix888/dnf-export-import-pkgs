#!/bin/bash
set -euo pipefail

get_help() {
    echo "Usage: sudo $0 -o <export|import> -p <filepath>"
    echo "\nOptions:"
    echo "  -o  Operation:"
    echo "        export - Save installed package names (excluding version/arch) to a file."
    echo "        import - Install packages from a file and remove packages not listed."
    echo "  -p  Filepath:"
    echo "        For export, file must not exist."
    echo "        For import, file must exist, be readable, and not be empty."
    exit 1
}

pkg_list_to_file() {
    local file="$1"
    [ -e "$file" ] && { echo "Error: $file already exists."; exit 1; }
    dnf repoquery --installed | awk -F '[:-]' '{print $1}' | sort -u > "$file"
    echo "Package list exported to $file."
}

get_delta() {
    sort -u "$2" | grep -Fxv -f "$1"
}

remove_file() {
    rm -f "$1" && echo "Removed temporary file: $1."
}

export_pkgs() {
    [ -z "$1" ] && { echo "Error: Empty filepath."; exit 1; }
    pkg_list_to_file "$1"
}

import_pkgs() {
    local file="$1"
    [ ! -r "$file" ] || [ ! -s "$file" ] && { echo "Error: File missing, unreadable, or empty."; exit 1; }
    
    local temp_list
    temp_list=$(mktemp) || { echo "Error: Failed to create temporary file."; exit 1; }
    trap 'rm -f "$temp_list"' EXIT
    
    pkg_list_to_file "$temp_list"
    
    mapfile -t to_delete < <(get_delta "$file" "$temp_list")
    [ ${#to_delete[@]} -gt 0 ] && dnf remove -y "${to_delete[@]}"
    
    pkg_list_to_file "$temp_list"
    
    mapfile -t to_install < <(get_delta "$temp_list" "$file")
    [ ${#to_install[@]} -gt 0 ] && dnf --setopt=install_weak_deps=False install -y "${to_install[@]}"
}

[ "$EUID" -ne 0 ] && { echo "Error: Root privileges required."; exit 1; }

operation=""
path=""

while getopts "o:p:" opt; do
    case "$opt" in
        o) operation="$OPTARG" ;;
        p) path="$OPTARG" ;;
        *) get_help ;;
    esac
done

[ -z "$operation" ] && get_help
case "$operation" in
    export) export_pkgs "$path" ;;
    import) import_pkgs "$path" ;;
    *) echo "Error: Invalid operation."; get_help ;;
esac
