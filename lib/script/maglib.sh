#!/bin/bash
declare -A command_definition=( 
    ["init"]="           -- :Initialize encrypted filesystem" 
    ["open"]="           -- :Mount encrypted filesystem"
    ["close"]="          -- :Unmount encrypted filesystem"
    ["install"]="        -- :Install mag executable to system"
    ["list"]="           -- :List decrypted files"
    ["tree"]="           -- :List decrypted files in tree format"
    ["search"]="         -- :Search decrypted files by name"
    ["update"]="         -- :Pull down the latest Magneto changes"
    ["wipe"]="           -- :Completely erase your encrypted data store."
)

command_list=()

crypt_dir="vault"
plain_dir="plain"

config_path="$project_path/mag.conf"

data_path=""
crypt_path=""
plain_path=""
git_path=""

for c in ${!command_definition[@]}; do
    command_list+=($c)
done

function read_config {
    if [ -f "$config_path" ]; then
        source "$config_path"
        
        if [[ "$MAG_DATA" != "" ]]; then 
            data_path="$(resolve_data_path $MAG_DATA)"
            check_path "$data_path" "Invalid MAG_DATA in mag.conf"

            crypt_path="$data_path/$crypt_dir"
            check_path "$data_path" "Cannot resolve crypt path from mag.conf. Is your MAG_DATA a valid path?"

            plain_path="$data_path/$plain_dir"
            check_path "$data_path" "Cannot resolve plain path from mag.conf. Is your MAG_DATA a valid path?"

            git_path="$data_path/.git"
        else
            fancy_println "bold" "red" "Invalid mag.conf"
            fancy_println "bold" "yellow" "Missing MAG_DATA_PATH"
        fi
    fi
}

function resolve_data_path {
    d=$1

    if [[ "$d" == /* ]]; then
        echo "$d"
    else
        echo "$project_path/$d"
    fi
}

function check_path {
    msg="$2"
    pathchk $1 > /dev/null 2>&1
    if [[ "$?" != 0 ]]; then
        fancy_println "bold" "red" "$msg"
        exit 1
    fi
}

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

    echo "$crypt_dir/gocryptfs.conf" >> .gitignore
    echo "plain" >> .gitignore

    git init 2>/dev/null | grep -v "hint" | sed 's|^Init|    - Init|'

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

function plain_list {
    find "$plain_path" -type f | sed -e "s|^$project_path||" | ctree
}

function plain_search {
    # echo "$1"
    # echo "$plain_path"
    find "$plain_path" -name "*$1*" 2>/dev/null | sed -e "s|^$project_path||" | ctree
    # find "$plain_path" -type f | grep "$1"
}

function ctree {
    $project_path/lib/ctree/ctree_linux_amd64
}