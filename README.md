# PHP-CI for Yii

This sets up a full Continuous Integration environment for PHP projects with the Yii Framework based on Debian servers

About
=====

When you are working on serious projects you want to introduce [Continuous Integration](http://martinfowler.com/articles/continuousIntegration.html) into your development routine. Unfortunately it is quite intimidating to set up a full environment and get started if you have never done it before.

There is an excellent intro at [jenkins-php.org](http://jenkins-php.org/), so this forms the basis of the CI environment set up by these scripts.

The magic behind the scenes is powered by [Ansible](http://www.ansibleworks.com/), a powerful yet simple way to manage servers. It requires only Python on the management machine, SSH access, and some knowledge of [YAML](http://www.yaml.org/), if you wish to adjust the installation yourself.

There are two ways how to perform the installation for PHP-CI

1. fully automated (fast and simple)
2. executing Ansible playbooks (advanced)

Disclaimer
==========

Please do not run any of these scripts on production servers or machine in the internet unless you know what you are doing. These scripts will not secure your installation and expose your systems to the world. Yes, even your source code! Best to run it on a machine behind a firewall that cannot be accessed from the outside.

Requirements
------------

In the following we assume you have at least one Debian machine, preferably running Debian Wheezy (7). 

Set up a Debian machine with a minimal installation. Use [the official documentation](http://www.debian.org/releases/stable/amd64/index.html.en), if needed.
All the testing was performed on a minimal install of Debian 7.3.0 AMD64 but it should work on any Debian system. It might also work on already pre-configured machines.

All required software will be taken care of by the `install.sh` script.

It helps to have some familiarity with the linux command line. Otherwise just don't be afraid and let the scripts do the heavy lifting.


Simple setup
------------
Copy the file `install.sh` to your Debian machine. Grab it from github and execute it with the following commands

```
$ wget https://raw.github.com/perlmonkey/php-ci/master/install.sh
$ /bin/bash install.sh
```

Now sit back and wait a while, the script first bootstraps [Ansible](http://www.ansibleworks.com/) on your machine and then installs [a LAMP stack](http://stackoverflow.com/questions/10060285/what-is-a-lamp-stack) plus the [Jenkins-CI](http://jenkins-php.org/) with a template for PHP projects (optimized slightly for use with [Yii](http://www.yiiframework.com/)).

Advanced setup
--------------

If you prefer to know what you're doing and are familiar with the linux shell and perhaps even Ansible, let's have a deeper look.

We assume the following:

* Management Machine: MacBook
* Management User: stephan
* Remote Server CI: 192.168.1.1
* Remote Server LAMP: 192.168.1.2

We'll only use Ansible playbooks, no need to use the shell script. But still, the setup is not optimized for security but rather to get you up and running as quickly as possible.

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

Make sure you can connect to the remote machine using ssh like this (the init must be performed as root):

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
macbook: stephan$ ssh myuser@10.211.55.4
```

Change the entry for _bootstrap_user_ in the file `playbooks/group_vars/all` to _myuser_ (or the name you provided in the init stage).

## Set up CI environment

Executing Playbooks
-------------------

Ready to bootstrap - you can now execute the `bootstrap.yml` playbook:

```
macbook: stephan$ ansible-playbook playbooks/bootstrap.yml -i playbooks/hosts/ci-hosts
```

Individual steps can be (de-)activated by explicitly calling certain tags using the `--tags="<tagname>"` switch. Only those mentioned will be executed then.


Roles
---------
### php-ci
* Deploys Jenkins CI with required PHP tools as pear modules
* can be invoked separately using the `--tags="php-ci"` attribute to the playbook command

### lamp
* Deploys a LAMP stack with Apache2 and MySQL and sets up a first site on port 80
* can be invoked separately using the `--tags="lamp"` attribute


Todo
----

Unfortunately the playbooks are not as clean as I would have wanted them to be. Especially since the _pear_ command is not very forgiving and produces errors that had to be ignored. Also currently only the Yii framework is really integrated as it is the one I work with. 

Changelog
---------
2014-01-23 - Initial release with support for Debian only