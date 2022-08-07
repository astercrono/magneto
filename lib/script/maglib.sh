#!/bin/bash
declare -A command_definition=( 
    ["init"]="           -- :Initialize encrypted filesystem" 
    ["open"]="           -- :Mount encrypted filesystem"
    ["close"]="          -- :Unmount encrypted filesystem"
    ["install"]="        -- :Install mag executable to system PATH (todo)"
    ["list"]="           -- :List decrypted files (todo)"
    ["search"]="         -- :Search decrypted files by GLOB (todo)"
    ["update"]="         -- :Pull down the latest Magneto changes (todo)"
)

command_list=()

data_dir="data"
crypt_dir="vault"
plain_dir="plain"

data_path="$project_path/$data_dir"
crypt_path="$data_path/$crypt_dir"
plain_path="$data_path/$plain_dir"
git_path="$data_path/.git"

for c in ${!command_definition[@]}; do
    command_list+=($c)
done

function print_help {
    fancy_print "bold" "cyan" "Usage: "
    echo "mag <command>"
    echo ""
    fancy_println "bold" "green" "Commands: "

    for c in ${command_list[@]}; do
        desc=$(command_description "$c" "full")
        fancy_print "bold" "    - $c"
        echo "$desc"
    done
}

function command_description {
    cmd="$1"
    full="$2"
    
    desc_array=${command_definition[$c]// /_}
    desc_array=(${desc_array[$c]//:/ })

    desc="${desc_array[1]//_/ }"
    tabin=""

    [[ "$full" == "full" ]] && tabin="${desc_array[0]//_/ }"

    echo "$tabin$desc"
}

function check_command {
    cmd="$1"
    for c in ${command_list[@]}; do
        [[ "$c" == "$cmd" ]] && return 0
    done
    return 1
}

function invalid_command {
    fancy_println "bold" "red" "Invalid Command: $1"
    echo ""
    print_help
}

function help_header {
    cmd="$1"
    cmd_desc=$(command_description "$cmd")

    fancy_print "bold" "Overview: "
    echo "$cmd_desc"

    echo ""

    fancy_print "bold" "cyan" "Usage: "
    echo "mag $cmd"
}

function crypt_init {
    mkdir -p "$crypt_path"
    run_gocryptfs -init "$crypt_path"
}

function crypt_open {
    mkdir -p "$plain_path"
    [ -d "$crypt_path" ] && [ -d "$plain_path" ] && run_gocryptfs $crypt_path $plain_path
}

function crypt_close {
    [ -d "$plain_path" ] && fusermount -u "$plain_path"
}

function git_init {
    cd "$data_path"

    echo "bin/**/gocrypt*" >> .gitignore
    echo "plain" >> .gitignore

    git init | grep -v "hint" | sed 's|^Init|    - Init|'

    cd "$project_path"

    if [[ -d "$git_path" ]]; then
        return 0
    else
        return 1
    fi
}

function is_mounted {
    if grep -qs "$plain_path" /proc/mounts; then
        return 0
    else
        return 1
    fi
}

function run_gocryptfs {
	local_gocrypt="$project_path/gocryptfs"

	if [ -f "$local_gocrypt" ]; then
		$local_gocrypt $@
	else
		gocryptfs $@
	fi
}
