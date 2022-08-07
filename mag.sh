#!/bin/bash

project_path=$(cd $(dirname $(realpath $0)) && pwd)
prereq_list=("gocryptfs" "git" "fusermount")

function prereq_check {
    missing_something=""
    missing=()

    for pr in ${prereq_list[@]}; do
        $(command -v "$pr" > /dev/null 2>&1)
        if [[ "$?" != 0 ]] && [ ! -f "$pr" ]; then
			missing+=("$pr")
			missing_something="1"
        fi
    done

    if [[ "$missing_something" == "1" ]]; then
        fancy_println "bold" "red" "Missing required dependencies: "
        for d in ${missing[@]}; do
            echo "    - $d"
        done
        exit 1
    fi
}

source "$project_path/lib/script/fancy.sh"
source "$project_path/lib/script/maglib.sh"

prereq_check
cmd="$1"

[[ "$cmd" == "" ]] && print_help && exit 1

check_command "$cmd"
[[ "$?" == 1 ]] && invalid_command "$cmd" && exit 1

function cmd_init {
    did_something=""

    if [ -d "$crypt_path" ]; then
        fancy_println "bold" "yellow" "Vault already initialized"
    else
        fancy_println "bold" "green" "Creating Vault"
        crypt_init
        [[ "$?" == 0 ]] && did_something="1"
    fi

    if is_mounted; then
        fancy_println "bold" "yellow" "Vault already mounted"
    else
        fancy_println "bold" "green" "Mounting Vault"
        crypt_open
        [[ "$?" == 0 ]] && did_something="1"
    fi

    if [ -d "$git_path" ]; then
        fancy_println "bold" "yellow" "Repository already configured"
    else
        fancy_println "bold" "cyan" "Configuring Git: "
        mkdir -p "$data_path"
        git_init         
        [[ "$?" == 0 ]] && did_something="1"
    fi

    if [[ "$did_something" == "1" ]]; then
        echo ""
        fancy_println "bold" "Done"
    fi
}

function cmd_open {
    if is_mounted; then
        fancy_println "bold" "yellow" "Vault already mounted"
    else
        fancy_println "bold" "green" "Mounting Vault"
        crypt_open

        echo ""
        fancy_println "bold" "Done"
    fi
}

function cmd_close {
    if is_mounted; then
        fancy_println "bold" "green" "Closing Vault"
        crypt_close

        echo ""
        fancy_println "bold" "Done"
    else
        fancy_println "bold" "yellow" "Vault already closed"
    fi
}

function cmd_install {
    alias_line="alias mag='$project_path/mag.sh'"
    targets=("$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")

    for t in ${targets[@]}; do
        if [ -f $t ]; then 
            echo "$alias_line" >> "$t"
        fi
    done
}

cmd_$cmd
