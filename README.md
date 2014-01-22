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

Set up a Debian machine with minimal installation. Use [the official documentation](http://www.debian.org/releases/stable/amd64/index.html.en), if needed.
All the testing was performed on a minimal install of Debian 7.3.0 AMD64 but it should work on any Debian system.

All required software will be taken care of by the `install.sh` script.

It helps to have some familiarity with the linux command line. Otherwise just don't be afraid and let the scripts do the heavy lifting.


Simple setup
------------
Copy the file `install.sh` to your Debian machine. Execute it with

```$ /bin/bash install.sh```

Now sit back and wait a while, the script first puts ansible on your machine and then installs [a LAMP stack](http://stackoverflow.com/questions/10060285/what-is-a-lamp-stack) plus the Jenkins-CI with a template for PHP projects.

Advanced setup
--------------

We assume the following:

* Management Machine: MacBook
* Management User: stephan
* Remote Server CI: 192.168.1.1
* Remote Server LAMP: 192.168.1.2

### Generate ssh keys on your management machine

The management machine in this example is called _MacBook_. The user is **stephan**

```
macbook: stephan$ ssh-keygen -t rsa
macbook: stephan$ ssh-keygen -t dsa
```

### Set up ssh connection to remote machine (10.211.55.4)

Setting up the remote machine so you can easily log in using ssh is done using the init playbook.

Add the remote host to your known hosts by connecting once via ssh:

```macbook: stephan$ ssh root@10.211.55.4```


On Mac OS X you need to make sure that sshpass is installed.

```macbook: stephan$ brew install https://raw.github.com/eugeneoden/homebrew/eca9de1/Library/Formula/sshpass.rb```

If you execute the init script it also creates a new user called ansible, so make sure you adjust the password to something sensible.

Take the hash for your password from the output of

``` openssl passwd -salt $1$SomeSalt$ -1 password```

Execute the init playbook:

```macbook: stephan$ ansible-playbook init.yml -i ./hosts -k```


Check if it works:

```macbook: stephan$ ssh ansible@10.211.55.4``

## Set up ansible to manage remote machine

First, install ansible on your machine (OS X) by using something like [HomeBrew](http://brew.sh/):

```
macbook: stephan$ ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"
macbook: stephan$ brew install ansible
```

Add host to ``hosts``:

```
[parallels]
10.211.55.4
```

Executing Playbooks
-------------------

Executing the playbooks for Ansible requires ansible to be available on all machines involved. If it is, executing the playbooks is as simple as running (`-K` is only required when password needs to be supplied for executing sudo)

  * `ansible-playbook baseinstall_ansible.yml -i ./hosts -k`
  
The -K switch asks for the sudo password.

  * `ansible-playbook baseinstall_ansible.yml -i ./hosts -K --tags "common,dev,mail,web"`

Individual steps can be (de-)activated by explicitly calling certain tags using the `--tags` switch.


Playbooks and Roles
---------
### common
* Installs some common packages
* setting the timezone based on an ansible variable

### update
* `apt-get update`

### devtools
* installs some development packages

### gmailrelay
* sets up exim4 to send emails using Google Mail

### munin
* Server monitoring using munin is set up
* requires nginx

### webserver
* sets up nginx as the webserver

### php5
* enables nginx to serve php pages

### mysql
* to be done