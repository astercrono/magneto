#!/bin/bash

project_path=$(cd $(dirname $(realpath $0)) && pwd)
prereq_list=("gocryptfs" "git" "fusermount" "ctree")

function prereq_check {
    missing_something=""
    missing=()

    for pr in "${prereq_list[@]}"; do
        command -v "$pr" >/dev/null 2>&1
        on_system="$?"

        if [ ! -f "$project_path/$pr" ] && [[ "$on_system" != 0 ]]; then
            missing+=("$pr")
            missing_something="1"
        else
            if [[ "$on_system" != 0 ]] && [ ! -f "$pr" ]; then
                missing+=("$pr")
                missing_something="1"
            fi
        fi
    done

    if [[ "$missing_something" == "1" ]]; then
        fancy_println "bold" "red" "Missing required dependencies: "
        for d in "${missing[@]}"; do
            echo "    - $d"
        done
        exit 1
    fi
}

source "$project_path/lib/script/fancy.sh"
source "$project_path/lib/script/maglib.sh"

prereq_check

function cmd_init {
    did_something=""

    if [ -d "$crypt_path" ]; then
        fancy_println "bold" "yellow" "Vault already initialized"
    else
        fancy_println "bold" "green" "Creating Vault"
        crypt_init
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
        fancy_println "bold" "Done"
    fi
}

function cmd_close {
    if is_mounted; then
        fancy_println "bold" "green" "Closing Vault"
        crypt_close
        fancy_println "bold" "Done"
    else
        fancy_println "bold" "yellow" "Vault already closed"
    fi
}

function cmd_install {
    mag_path_line="export MAGPATH=$project_path"
    path_line="PATH=\$MAGPATH:\$PATH"
    targets=("$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")

    for t in "${targets[@]}"; do
        if [ -f $t ]; then
            echo "$mag_path_line" >>"$t"
            echo "$path_line" >>"$t"
        fi
    done
}

function cmd_wipe {
    if is_mounted; then
        fancy_println "bold" "green" "Closing Vault"
        crypt_close
    fi

    if [ -d "$data_path" ]; then
        read -p "Re-enter vaule name: " entered_vault

        if [[ "$VAULT_NAME" == "$entered_vault" ]]; then
            fancy_println "bold" "yellow" "Wiping data store"
            rm -fr $data_path
        else
            fancy_println "bold" "Invalid Vault Name"
            exit 1
        fi
    fi

    fancy_println "bold" "Done"
}

function cmd_list {
    plain_list
}

function cmd_search {
    exp="$1"

    if [[ "$exp" == "" ]]; then
        fancy_println "bold" "red" "Missing argument: <name>"
        echo ""
        fancy_print "bold" "cyan" "Usage: "
        echo "mag search <name>"
        echo ""
        fancy_print "bold" "<name>"
        echo ": File name substring to search for"
        exit 1
    fi

    plain_search "$exp"
}

function cmd_pull {
    pushd .

    cd "$project_path/$MAG_DATA"
    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Invalid vault path" && exit 1

    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Invalid repo. Could not determine branch." && exit 1

    git fetch && \
    git merge "origin/$current_branch"

    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Unable to pull changes from remote" && exit 1

    popd
}

function cmd_push {
    pushd .

    cd "$project_path/$MAG_DATA"
    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Invalid vault path" && exit 1

    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Invalid repo. Could not determine branch." && exit 1

    git fetch && \
    git merge "origin/$current_branch" && \
    git push origin "$current_branch"

    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Unable to push to remote" && exit 1

    popd
}

function cmd_commit {
    pushd .

    cd "$project_path/$MAG_DATA"
    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Invalid vault path" && exit 1

    git add . && \
    git commit

    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Unable to commit" && exit 1

    popd
}

function cmd_auto_commit {
    pushd . >/dev/null

    cd "$project_path/$MAG_DATA"
    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Invalid vault path" && exit 1

    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Invalid repo. Could not determine branch." && exit 1

    git add . && \
    git commit -m "Update vault data"

    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Unable to auto-commit" && exit 1

    popd >/dev/null
}

function cmd_sync {
    pushd . >/dev/null

    cd "$project_path/$MAG_DATA"
    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Invalid vault path" && exit 1

    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Invalid repo. Could not determine branch." && exit 1

    git fetch && \
    git merge "origin/$current_branch" && \
    git add . && \
    git commit -m "Update vault data" && \
    git push origin "$current_branch"

    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Unable to sync with remote" && exit 1

    popd >/dev/null
}

function cmd_remote {
    url="$1"

    if [[ "$url" == "" ]]; then
        fancy_println "bold" "red" "Missing argument: <url>"
        echo ""
        fancy_print "bold" "cyan" "Usage: "
        echo "mag [vault] remote <url>"
        echo ""
        fancy_print "bold" "<name>"
        echo ": URL to add as origin"
        exit 1
    fi

    pushd . >/dev/null

    cd "$project_path/$MAG_DATA"
    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Invalid vault path" && exit 1

    if [[ "$(git remote)" == "" ]]; then
        echo "adding"
        git remote add origin "$url"
    else
        echo "setting"
        git remote set-url origin "$url"
    fi

    [[ "$?" != 0 ]] && fancy_println "bold" "red" "Unable to change remote" && exit 1

    popd >/dev/null
}

function cmd_vaults {
    if [ ! -d "$project_path/data" ]; then
        fancy_println "bold" "yellow" "Data directory missing"
    else
        ls "$project_path/data"
    fi
}

first_arg="$1"
second_arg="$2"

[[ "$first_arg" == "" ]] && print_help && exit 1

check_command "$first_arg"
is_command="$?"

if [[ "$is_command" == 0 ]]; then
    MAG_DATA="main"
    cmd="$first_arg"
    shift
else
    check_command "$second_arg"
    is_command="$?"

    if [[ "$is_command" == 0 ]]; then
        MAG_DATA="$first_arg"
        cmd="$second_arg"
        shift
        shift
    fi
fi

[[ "$MAG_DATA" == "" ]] && invalid_args "$cmd" && exit 1

if [[ "$cmd" != "vaults" ]]; then
    fancy_print "bold" "magenta" "Target Vault: "
    echo "$MAG_DATA"
    echo ""
fi

VAULT_NAME="$MAG_DATA"
MAG_DATA="data/$MAG_DATA"
set_mag_paths
cmd_"$cmd" "$@"
