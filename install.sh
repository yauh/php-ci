#!/bin/bash
# install.sh is used to bootstrap the php-ci environment on a single machine
# Author: Stephan Hochhaus <stephan@yauh.de>
# Link: https://github.com/perlmonkey/php-ci
# This script requires
# * freshly installed Debian Wheezy 7.x
# * connection to the internet from the machine
# * (optional) firewall to prevent users form the internet to access the machine directly

clear
echo "*********************************************"
echo "* Setting up this computer as a PHP-CI      *"
echo "* Like described at http://jenkins-php.org/ *"
echo "* * * * * * * * * WARNING * * * * * * * * * *"
echo "* Please make sure this machine cannot be   *"
echo "* accessed from the internet                *"
echo "* Or that you harden it after the install   *"
echo "*********************************************"
echo "Do you really want to continue? (y/n)"
read letsgo

if  [ $letsgo == y ]; then
  # We expect the root user to be used for this action
  # also the machine must accept root to connect using ssh and a password
  PASS="password"
  echo "Great. Now please enter the root password to access this machine: "
  read PASS
else
  echo "Nothing to be done."
  exit 1
fi

# Install ssh software on a minimal Debian system
#apt-get update
apt-get -y install ssh sshpass

# check if ssh access works
export SSH_CONNECT=false
sshpass  -p $PASS ssh -o StrictHostKeyChecking=no root@127.0.0.1 cat /etc/hostname && export SSH_CONNECT=true

echo $SSH_CONNECT
if  [ $SSH_CONNECT == false ]; then
  echo "Nothing can be done, ssh connection not possible (was your password correct?)"
  exit 1
elif [ $SSH_CONNECT == true ]; then
  echo "For the record: ssh can connect, hooray"
else
  exit 1
fi

echo "Ok, now grab a cup of coffee, give me a couple of minutes to set things up"

# Install all package requirements
apt-get -y install sudo expect autoconf gcc python python-all python-all-dev python-setuptools git

# Install Ansible using pip
easy_install pip
pip install paramiko PyYAML jinja2 httplib2
pip install ansible

# clone the php-ci repository to /tmp or git pull if already present
cd /tmp
git clone https://github.com/perlmonkey/php-ci.git || cd /tmp/php-ci && git pull

# Perform the ansible playbook using the root password given above
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
echo "All done, hopefully you can enjoy your new PHP-CI environment on port 8080 now"