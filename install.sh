#!/bin/bash
# install.sh is used to bootstrap the php-ci environment on a single machine
# Author: Stephan Hochhaus <stephan@yauh.de>
# Link: https://github.com/perlmonkey/php-ci
#
# This script requires
# * freshly installed Debian Wheezy 7.x
# * connection to the internet from the machine
# * (strongly suggested) firewall to prevent users form the internet to access the machine directly
# setting some variables first
SSH_CONNECT=not_successful
USER=`whoami`
SUDO_PASSWORD_REQUIRED=false

# here the magic begins
clear
echo "*************************************************************************"
echo "*                 Setting up this computer as a PHP-CI                  *"
echo "*        Based on descriptions found at http://jenkins-php.org/         *"
echo "*-----------------------------------------------------------------------*"
echo "* WARNING:  Please make sure this machine cannot be                     *"
echo "*           accessed from the internet                                  *"
echo "*           Or that you harden it after the install                     *"
echo "*************************************************************************"
echo "******* You are running this script as $USER"
if  [ -z $SUDO_USER  ]; then # if SUDO_USER is set it means we're running on sudo
  echo "******* If you see any errors make sure this user has sudo privileges"
  echo "******* This can be done using the command $ adduser <usernamer> sudo"
else
  echo "******* But we know you are $SUDO_USER"
fi
echo "******* Please note:"
echo "******* Never enter any commands during the process!"
echo "******* Only if you see a line beginning with *INPUT* like this:"
echo "*INPUT* Do you really want to continue? (y/n)"
read LETSGO
# for debugging purposes we can assume it is y
#LETSGO=y



if  [ $LETSGO == y ]; then
  # We expect the root user to be used for this action
  # also the machine must accept root to connect using ssh and a password
  echo "******* Great. Let's go and check the prerequisites"
  echo "*INPUT* But first please enter your user password"
  read USER_PASSWD
  # again, for debugging purposes we can assume it is password
  #USER_PASSWD="password"
else
  echo "******* Nothing to be done."
  exit 1
fi

# Install ssh software on a minimal system
echo "******* First we make sure some essential software is installed"
if  [ -z $SUDO_USER  ]; then # if SUDO_USER is set it means we're running on sudo
  apt-get update > /dev/null 2>&1 || { echo '*ERROR* You do not have sufficient privileges to continue.'; echo '******* Consider using sudo or become root' ; exit 1; }
  apt-get -y install sudo ssh sshpass > /dev/null 2>&1
else
  sudo apt-get update > /dev/null 2>&1
  sudo apt-get -y install ssh sshpass > /dev/null 2>&1
fi


# Let's check if ssh can connect
echo "******* Checking SSH connect works"
if  [ -z $SUDO_USER  ]; then 
  sshpass -p $USER_PASSWD ssh -o StrictHostKeyChecking=no $USER@127.0.0.1 cat /etc/hostname > /dev/null 2>&1 && SSH_CONNECT=successful
else
  sshpass -p $USER_PASSWD ssh -o StrictHostKeyChecking=no $SUDO_USER@127.0.0.1 cat /etc/hostname > /dev/null 2>&1 && SSH_CONNECT=successful
fi
if  [ $SSH_CONNECT == not_successful ]; then
  echo "*ERROR* SSH-Connection not successful"
  exit 1
else
  echo "******* SSH-Connection successful"
fi

# @TODO: This appears to be non-functional?!
# workaround is setting the variable manually and always assuming sudo password is required
# Check if sudo requires a password - needed for ansible-playbooks later on
echo "******* Now checking whether sudo requires a password"
if  [ -z $SUDO_USER  ]; then 
  sshpass -p $USER_PASSWD ssh -o StrictHostKeyChecking=no $USER@127.0.0.1 sudo cat /etc/hostname > /dev/null 2>&1 || SUDO_PASSWORD_REQUIRED=true
else
  sshpass -p $USER_PASSWD ssh -o StrictHostKeyChecking=no $SUDO_USER@127.0.0.1 sudo cat /etc/hostname > /dev/null 2>&1 || SUDO_PASSWORD_REQUIRED=true
fi

if  [ SUDO_PASSWORD_REQUIRED == true  ]; then 
  echo "******* We need a sudo password indeed"
fi

echo "******* Ok, now give me a couple of minutes to set things up"

# Install all package requirements
echo "******* Installing more required software"
if  [ -z $SUDO_USER  ]; then # if SUDO_USER is set it means we're running on sudo
  apt-get -y install expect autoconf gcc python python-all python-all-dev python-setuptools git > /dev/null 2>&1
else
  sudo apt-get -y install expect autoconf gcc python python-all python-all-dev python-setuptools git > /dev/null 2>&1
fi

# Install Ansible using pip
echo "******* Setting up Ansible using pip"
if  [ -z $SUDO_USER  ]; then # if SUDO_USER is set it means we're running on sudo
  easy_install pip > /dev/null 2>&1
  pip install paramiko PyYAML jinja2 httplib2 ansible > /dev/null 2>&1
else
  sudo easy_install pip > /dev/null 2>&1
  sudo pip install paramiko PyYAML jinja2 httplib2 ansible > /dev/null 2>&1
fi

# clone the php-ci repository to /tmp or git pull if already present
cd /tmp
echo "******* Cloning into perlmonkey/php-ci"
git clone https://github.com/perlmonkey/php-ci.git > /dev/null 2>&1 || cd /tmp/php-ci && git reset --hard HEAD && git pull > /dev/null 2>&1

# Adjust the username in the vars file so ansible knows whose personality to use
if  [ -z $SUDO_USER  ]; then 
  sed -i "/change this to your user account that manages the server/c\bootstrap_user: $USER" /tmp/php-ci/playbooks/group_vars/all
else
  sed -i "/change this to your user account that manages the server/c\bootstrap_user: $SUDO_USER" /tmp/php-ci/playbooks/group_vars/all
fi

ansible_command="/usr/local/bin/ansible-playbook " # call ansible-playbook
ansible_command+="/tmp/php-ci/playbooks/bootstrap.yml" # using the bootstrap playbook
ansible_command+=" -i /tmp/php-ci/playbooks/hosts/localhost" # and the localhost hosts-file
ansible_command+=" -k" # ask for a ssh password

# if SUDO_PASSWORD_REQUIRED==true we need to supply -K to ansible
if  [ $SUDO_PASSWORD_REQUIRED == 'true'  ]; then 
  ansible_command+=" -K" # ask for a ssh password
fi

# if you like ansible to be chatty (for debugging purposes)
#ansible_command+=" -vvv" # be very verbose

echo "******* Starting ansible with $ansible_command"

# Perform the ansible playbook using the root password given above
echo "******* Executing ansible playbooks"
echo "******* Now you'll see some more logging messages from ansible"

expect -c "
   set timeout -1
   spawn $ansible_command
   expect password { send $USER_PASSWD\r ; exp_continue }
   expect sudo { send $USER_PASSWD\r }
   exit
"

# And we're done.
echo "******* Congratulations, you're done."