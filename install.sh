#!/bin/bash
# install.sh is used to bootstrap the php-ci environment on a single machine
# Author: Stephan Hochhaus <stephan@yauh.de>
# Link: https://github.com/perlmonkey/php-ci
# This script requires
# * freshly installed Debian Wheezy 7.x
# * connection to the internet from the machine
# * (optional) firewall to prevent users form the internet to access the machine directly

echo "****************************************"
echo "* Setting up this computer as a PHP-CI *"
echo "****************************************"
echo "Do you want to continue? (y/n)"
read letsgo

if  [ $letsgo == y ]; then
  echo "Ok, grab a cup of coffee, give me a couple of minutes"
  # We expect the root user to be used for this action
  # also the machine must accept root to connect using ssh and a password
  PASS="password"
  echo "Please enter the root password to access this machine: "
  read PASS
else
  echo "Nothing to be done."
  exit 1
fi

# Install ssh software on a minimal Debian system
#apt-get update
apt-get -y install ssh
echo $PASS
# check if ssh access works
expect <<- SSHTESTEND
    set timeout 2

    spawn ssh -o StrictHostKeyChecking=no root@127.0.0.1 cat /etc/hostname

    # Wait for password prompt
    expect "*?assword:*"
    # Send password aka $PASS
    send -- "$PASS\r"

    expect eof
SSHTESTEND

echo "ssh can connect, that's good!"
echo "Ok, now grab a cup of coffee, give me a couple of minutes to set things up"

# Install all other requirements
apt-get -y install sudo sshpass autoconf expect gcc python python-all python-all-dev python-setuptools git


# Install Ansible using pip
easy_install pip
pip install paramiko PyYAML jinja2 httplib2
pip install ansible

# clone the php-ci repository to /tmp
cd /tmp
git clone https://github.com/perlmonkey/php-ci.git || cd /tmp/php-ci && git pull

# Perform the ansible playbook using the passwort given
export ANSIBLE_HOST_KEY_CHECKING=False
expect <<- DONE
  set timeout -1

  spawn /usr/local/bin/ansible-playbook /tmp/php-ci/bootstrap.yml -i /tmp/php-ci/ci-hosts -k

  # Wait for password prompt
  expect "*?assword:*"
  # Send password stored in $PASS
  send -- "$PASS\r"

  expect eof
DONE

echo "All done, enjoy your new PHP-CI environment on port 8080"