#!/bin/bash -e
#!/usr/bin/env bash

apt_wait () {
    while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
        sleep 1
        echo "dpkg is locked"
    done
    while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
        sleep 1
        echo "apt/lists is locked"
    done
    if [ -f /var/log/unattended-upgrades/unattended-upgrades.log ]; then
        while sudo fuser /var/log/unattended-upgrades/unattended-upgrades.log >/dev/null 2>&1 ; do
        sleep 1
        echo "unattended-upgrade"
        done
    fi
}

delete_lock () {
    name=$1
    echo "deleting apt/lists/lock"
    sudo rm /var/lib/apt/lists/lock
    echo "deleting apt/archives/lock"
    sudo rm /var/cache/apt/archives/lock
    echo "deleteing dpkg/lock"
    sudo rm /var/lib/dpkg/lock

    sudo apt-get -y install $name
}

main() {
    sudo apt-get update
    sudo apt-get -y install --no-install-recommends --fix-missing ubuntu-desktop 
}

main