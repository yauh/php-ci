# PHP-CI for Yii

This sets up a full Continuous Integration environment for PHP projects with the Yii Framework based on Debian-based servers.

About
=====

When you are working on serious projects you want to introduce [Continuous Integration](http://martinfowler.com/articles/continuousIntegration.html) into your development routine. Unfortunately it is quite intimidating to set up a full environment and get started if you have never done it before.

There is an excellent intro at [jenkins-php.org](http://jenkins-php.org/), so this forms the basis of the CI environment set up by these scripts.

The magic behind the scenes is powered by [Ansible](http://www.ansibleworks.com/), a powerful yet simple way to manage servers. It requires only Python on the management machine, SSH access, and some knowledge of [YAML](http://www.yaml.org/), if you wish to adjust the installation yourself.

There are two ways how to perform the installation for PHP-CI

1. fully automated (fast and simple) - just download a file and execute it
2. executing Ansible playbooks (advanced)

Disclaimer
==========

Please do not run any of these scripts on production servers or machines directly accesible from the internet unless you know what you are doing. **These scripts will not secure your installation and expose your systems to the world.**
Yes, even your source code will be accessible to anyone!

Best to run it on a machine behind a firewall that cannot be accessed from the outside.

Requirements
------------

In the following we assume you have at least one Debian machine, preferably running Debian Wheezy (7). 

Set up a Debian machine with a minimal installation. Use [the official documentation](http://www.debian.org/releases/stable/amd64/index.html.en), if needed.
All the testing was performed on a minimal install of Debian 7.3.0 AMD64 as well as Ubuntu Server 12.04 but it should work on any Debian system. It might also work on already pre-configured machines.

All required software will be taken care of by the `install.sh` script.

It helps to have some familiarity with the linux command line. Otherwise just don't be afraid and let the scripts do the heavy lifting.


Simple setup
------------
Copy the file `install.sh` to your Debian/Ubuntu machine. Log into your machine that is going to be the PHP server and start the deployment with the following commands

```
$ wget https://raw.github.com/yauh/php-ci/master/install.sh
$ sudo /bin/bash install.sh
```

The script asks you to enter the port where the Jenkins CI instance is supposed to listen on. The default is 8080. You may set it to anything else, but not 80 as that is already used by the Apache that comes with the automated installation.
Then you must provide your user password that enables the connection.

Now sit back and wait a while, the script first bootstraps [Ansible](http://www.ansibleworks.com/) on your machine and then installs [a LAMP stack](http://stackoverflow.com/questions/10060285/what-is-a-lamp-stack) plus the [Jenkins-CI](http://jenkins-php.org/) with a template for PHP projects (optimized slightly for use with [Yii](http://www.yiiframework.com/)).

Also you can watch me [perform a simple setup on Youtube](https://www.youtube.com/watch?v=MPjR4mgh_E0). (Beware, the video is a bit outdated even though the principle is still the same!)

Advanced setup
--------------

## Cloning into php-ci

Since the individual roles are used as submodules make sure you check them out correctly, e.g. like this:

```
$ git clone https://github.com/yauh/php-ci.git
$ cd php-ci
$ git submodule init && git submodule update

```

## Using the playbooks

If you prefer to know what you're doing and are familiar with the linux shell and perhaps even Ansible, let's have a deeper look.

We'll only use Ansible playbooks, no need to use the shell script (*install.sh*). But still, the setup is not optimized for security but rather to get you up and running as quickly as possible.

Ansible uses playbooks to perform tasks. These may be parameterized in that some tasks are only performed on dedicated LAMP servers, others only on CI machines. You organize all your machines in the `playbooks/hosts/ci-hosts` file. You may use IPs or hostnames.

For all tasks carried out there are some switches you can adjust - the variables. You can specifically set variables inside a role or override it for a specific host or a group of hosts (check `playbooks/group_vars/all`).

We assume the following setup for the next steps:

* Management Machine: MacBook
* Management User: stephan
* Remote Server CI: 192.168.1.1
* Remote Server LAMP: 192.168.1.2

### Generate ssh keys on your management machine

```
macbook: stephan$ ssh-keygen -t rsa
```

### Install Ansible 

Install Ansible on your management machine according to [the installation documentation](http://docs.ansible.com/intro_installation.html). If you must run it [on Windows you can do so using Cygwin](https://servercheck.in/blog/running-ansible-within-windows) although it is not officially supported.

On Mac OS X you should use [homebrew](http://brew.sh).

```
macbook: stephan$ ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"
macbook: stephan$ brew install ansible
```

### Define your environment

In order for the playbooks to work you need to define which machines to run on. There are two types of server: *CI* and *LAMP*. Both can run on the same machine if you wish, but you can also separate them if you want.

Go to `playbooks/hosts/ci-hosts` and adjust the hostnames or IP addresses for the machines where you want to perform the deployment.

### Set up ssh connection to remote machines

Setting up the remote machine so you can easily log in using ssh is done using the init playbook. It will

* set up a user and password as defined in the _vars_ section in `init.yml` (create a password on the shell using `$ openssl passwd -salt <salt> -1 <plaintext>`)
* copy your ssh key to the remote machine so you can connect without a password through ssh
* refresh your packages and install some basic software
* enables sudo without a password for your newly created user

Make sure you can connect to the remote machine using ssh like this (the init must be performed as root or with sudo powers):

```
macbook: stephan$ ssh root@192.168.2.1 cat /etc/hostname
```
Go to the root of the php-ci project and execute the playbook like this
```
macbook: stephan$ ansible-playbook playbooks/init.yml -i playbooks/hosts/ci-hosts -k
```

On Mac OS X you need to make sure that sshpass is installed. Assuming you use [homebrew](http://brew.sh/) you can install it like this:

```
macbook: stephan$ brew install https://raw.github.com/eugeneoden/homebrew/eca9de1/Library/Formula/sshpass.rb
```

Check if it works (if you changed _myuser_ in the _vars_ section to something else, adjust the command accordingly):

```
macbook: stephan$ ssh myuser@192.168.1.1
```

Change the entry for _bootstrap_user_ in the file `playbooks/group_vars/all` to _myuser_ (or the name you provided in the init stage).

## Set up CI environment

Executing Playbooks
-------------------

Ready to bootstrap - you can now execute the `bootstrap.yml` playbook:

```
macbook: stephan$ ansible-playbook playbooks/bootstrap.yml -i playbooks/hosts/ci-hosts
```

Individual steps (read: roles) can be (de-)activated by explicitly calling certain tags using the `--tags="<tagname>"` switch. Only those mentioned will be executed then.


Roles
---------
### role-common
* Typical tasks to be performed on any server
* can be invoked separately using the `--tags="common"` attribute to the playbook command

### role-msmtp
* If you already have a mail server and want to use it with SMTP (e.g. GMail or iCloud) instead of a full blown mail server use this. Then Jenkins can also send you mails.
* can be invoked separately using the `--tags="mail"` attribute to the playbook command

### role-jenkins-php
* Deploys Jenkins CI with required PHP tools as pear modules
* It also sets up [a demonstration job](https://github.com/yauh/yii-sample-project) using the yii framework
* can be invoked separately using the `--tags="php-ci"` attribute to the playbook command

### role-lamp
* Deploys a LAMP stack with Apache2 and MySQL and sets up a first site on port 80
* can be invoked separately using the `--tags="lamp"` attribute

### role-hardening
* Tasks that will make your server more secure. Only execute these if you know what you are doing.
* can be invoked separately using the `--tags="hardening"` attribute to the playbook command

Known Issues
-------------
Sometimes during the execution of *role-jenkins-php* the last step - triggering a build for the example project - will fail. This has no effect on your setup, it just means you need to start the first build manually.

Unless you provide proper credentials for your SMTP server, *role-msmtp* will always fail.

Changelog
---------
2014-01-25 - v0.0.3 Restructured project to use roles as submodules

2014-01-24 - v0.0.2 Massive Ansible and install.sh cleanup. Now with Ubuntu support

2014-01-23 - v0.0.1 Initial release with support for Debian only