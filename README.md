# Magneto

## Overview

Magneto is a shell wrapper around [gocryptfs](https://github.com/rfjakob/gocryptfs) that lets you easily manage multiple encrypted filesystems. In addition
to being an orchestration tool, Magento also sets filesystems up as Git repositories and provides commands for
managing them.

Use Magneto to manage multiple distinct, version-tracked, encrypted filesystems.

## Setup

### Prerequisites

 - [gocryptfs](https://github.com/rfjakob/gocryptfs)
 - git
 - fuse, fusermount
 - [ctree](https://github.com/astercrono/crono-tools)

### Clone Repository

`git clone https://gitlab.com/cronolabs/magneto.git`

### Install to PATH

`cd magneto && ./mag.sh install`

## Usage

```shell
$ mag
Usage: mag [vault] <command>

Arguments: 
    - vault          -- (optional) Name of vault to operate on. Default: main
    - command        -- Action to perform

Commands: 
    - auto_commit    -- Commit vault changes
    - close          -- Unmount encrypted filesystem
    - commit         -- Commit vault changes
    - git            -- Perform Git commands on vault
    - init           -- Initialize encrypted filesystem
    - install        -- Install mag executable to system
    - list           -- List decrypted files
    - open           -- Mount encrypted filesystem
    - pull           -- Pull down the latest vault changes
    - push           -- Push vault changes to remote
    - remote         -- Set remote URL
    - search         -- Search decrypted files by name
    - sync           -- Fetch, merge, auto-commit and push vault
    - tree           -- List decrypted files in tree format
    - vaults         -- List available vaults
    - wipe           -- Completely erase your encrypted data store.
```

Magneto refers to each encrypted filesystem as a Vault. Let's walk through some setup and usage.

### Creating a Vault

`$ mag mystash init`

This will create a new vault under the name `mystash`.

 - All vaults are located under `<project_directory>/data`. 
 - Encrypted data is located under `<project_directory>/data/<vault_name>/vault`. 
 - Decrypted data is located under `<project_directory>/data/<vault_name>/plain`. 

*Note: I highly recommend copying the mag vault password and master key into a separate, safe storage location.*

### Opening a Vault

`$ mag mystash open`

### Listing and Searching

List all contents: `mag mystash list`.

Search for a directory and/or file by name: `mag mystash search <search_string>`.

**Example 1**
```shell
$ mag mystash search really
Target Vault: mystash

/
    data/
        mystash/
            plain/
                test/
                    subdir/
                        deeper_dir/
                            reallyorange
```

**Example 2**
```shell
$ mag mystash search test/
Target Vault: mystash

/
    data/
        mystash/
            plain/
                test/
                    subdir/
                        deeper_dir/
                            red
                            green
                            blue
                            reallyorange
                        567f
                        1234
                        abcd
                        fggfggfgg9
                    abcd
                    1234
                    567f
                    fggfggfgg9
```
### Closing

When no longer using the vault, it is recommended to close it: `mag mystash close`.

### List Available Vaults

Get a list of all vaults under `<project_directory>/data`:
```shell
$ mag vaults
mystash
```

### Destroying a Vault

If you wish to delete your vault from existence: `mag mystash wipe`

*This is an irreversible operation.*

## License

This software is licensed under [The MIT License](LICENSE)
