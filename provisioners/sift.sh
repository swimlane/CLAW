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

    wget -O - https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
    echo "downloaded saltstack"
    echo "deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest xenial main" | sudo tee /etc/apt/sources.list.d/saltstack.list
    echo "adding saltstack to source list"
    apt_wait
    echo "updating apt-get"
    sudo apt-get -y update

    apt_wait
    echo "installing salt-minion"
    sudo apt-get -y install salt-minion || delete_lock 'salt-minion'
    apt_wait
    echo "stopping salt-minion"
    sudo service salt-minion stop
    apt_wait
    # Snag the binaries - https://github.com/sans-dfir/sift-cli
    echo "downloading sift cli"
    sudo curl -Lo /usr/local/bin/sift https://github.com/sans-dfir/sift-cli/releases/download/v1.7.1/sift-cli-linux
    echo "chmod sift cli"
    sudo chmod +x /usr/local/bin/sift

    apt_wait
    # Install SIFT
    echo "installing sift"
    sudo sift install --mode=packages-only
}

main