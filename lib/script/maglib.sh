#!/bin/bash
declare -A command_definition=( 
    ["init"]="           -- :Initialize encrypted filesystem" 
    ["open"]="           -- :Mount encrypted filesystem"
    ["close"]="          -- :Unmount encrypted filesystem"
    ["install"]="        -- :Install mag executable to system"
    ["list"]="           -- :List decrypted files"
    ["tree"]="           -- :List decrypted files in tree format"
    ["search"]="         -- :Search decrypted files by name"
    ["pull"]="           -- :Pull down the latest vault changes"
    ["push"]="           -- :Push vault changes to remote"
    ["commit"]="         -- :Commit vault changes"
    ["auto_commit"]="    -- :Commit vault changes"
    ["sync"]="           -- :Fetch, merge, auto-commit and push vault"
    ["remote"]="         -- :Set remote URL"
    ["git"]="            -- :Perform Git commands on vault"
    ["vaults"]="         -- :List available vaults"
    ["wipe"]="           -- :Completely erase your encrypted data store."
)

command_list=()

crypt_dir="vault"
plain_dir="plain"

data_path=""
crypt_path=""
plain_path=""
git_path=""

for c in "${!command_definition[@]}"; do
    command_list+=($c)
done

function set_mag_paths {
    if [[ "$MAG_DATA" != "" ]]; then
        data_path="$(resolve_data_path $MAG_DATA)"
        check_path "$data_path" "Invalid MAG_DATA"

        crypt_path="$data_path/$crypt_dir"
        check_path "$data_path" "Cannot resolve crypt path. Is your MAG_DATA a valid path?"

        plain_path="$data_path/$plain_dir"
        check_path "$data_path" "Cannot resolve plain path. Is your MAG_DATA a valid path?"

        git_path="$data_path/.git"
    else
        fancy_println "bold" "red" "Invalid MAG_DATA"
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
    echo "mag [vault] <command>"
    echo ""
    fancy_println "bold" "green" "Arguments: "
    fancy_print "bold" "    - vault"
    fancy_print "normal" "          -- (optional) Name of vault to operate on. "
    fancy_print "bold" "Default"
    echo ": main"
    fancy_print "bold" "    - command"
    echo "        -- Action to perform"
    echo ""
    fancy_println "bold" "green" "Commands: "

    for c in "${command_list[@]}"; do
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
    for c in "${command_list[@]}"; do
        [[ "$c" == "$cmd" ]] && return 0
    done
    return 1
}

function invalid_args {
    fancy_println "bold" "red" "Invalid Arguments"
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
		$local_gocrypt "$@"
	else
		gocryptfs "$@"
	fi
}

function plain_list {
    find "$plain_path" -type f | sed -e "s|^$project_path||" | ctree
}

function plain_search {
    search_name="$1"
    find "$plain_path" -type f 2>/dev/null | grep -i "$search_name" | sed -e "s|^$project_path||" | ctree
}

function ctree {
    # TODO - Select platform and arch specific ctree
    chmod +x $project_path/lib/ctree/ctree_linux_amd64
    $project_path/lib/ctree/ctree_linux_amd64
}