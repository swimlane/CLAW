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

    apt_wait

    # Now let's install our S3 bucket
    echo "installing s3 bucket libs"
    sudo apt-get -y install automake autotools-dev fuse g++ git libcurl4-gnutls-dev libfuse-dev libssl-dev libxml2-dev make pkg-config

    git clone https://github.com/s3fs-fuse/s3fs-fuse.git
    cd s3fs-fuse
    ./autogen.sh
    ./configure
    make
    sudo make install

    # Create password file
    sudo vi /etc/passwd-s3fs
    echo "ACCESS_KEY_ID:SECRET_KEY_ID" >> /etc/passwd-s3fs
    sudo chmod 640 /etc/passwd-s3fs

    # Mount s3 bucket
    sudo mkdir -p /s3/bucket-test
    sudo s3fs -o allow_other a-test-bucket-124568d /s3/bucket-test
}

main