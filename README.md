
# belet_seri

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with belet_seri](#setup)
    * [What belet_seri installs](#what-belet_seri-installs)
    * [Setup requirements](#setup-requirements)
    * [Beginning with belet_seri](#beginning-with-belet_seri)
3. [Setting up your Ubuntu Box](#setting-up-your-ubuntu-box)
4. [Installing and setting up Puppet on your Ubuntu Box](#installing-and-setting-up-puppet-on-your-ubuntu-box)
5. [Getting and using belet_seri](#getting-and-using-belet_seri)
6. [Testing it's ALIVE!?](#testing-its-alive)

## Description

This module was created to facilitate the quick and easy setup for an App backend. It sets up a basic REST Api on Ubuntu. using Ruby, Sinatra (a ruby gem), NGINX (an HTTP server) and MySQL

It's Free and Open Source, so you can use away and modify it all you like! Iy also installs free and open source stuff so no need to worry about that either. 

We have a video to guide you through these steps and to explain more about the module: https://www.youtube.com/watch?v=whVHXnNKSwY

I would recommend completing the Puppet Learning VM before using this, as it helps explain a few of the concepts: https://puppet.com/download-learning-vm

## Setup

### What belet_seri installs

It will install the NGINX package and configure it

It will install the Sinatra ruby gem as well as the MySQL ruby gem. These require a few development packages that will also be installed

And finally it will install MySQL and create a single table in it. 


### Setup Requirements 

Run on Ubuntu 16.04. I didn't have time to add any other OSes

## Setup

### What belet_seri installs

It will install the NGINX package and configure it

It will install the Sinatra ruby gem as well as the MySQL ruby gem. These require a few development packages that will also be installed

And finally it will install MySQL and create a single table in it. 


### Setup Requirements 

Run on Ubuntu 16.04. I didn't have time to add any other OSes

### Beginning with belet_seri  

Simply clone this module into the module folder (Explained below) and add it to your site.pp file. (also explained below)

## Setting up your Ubuntu Box

I'm glosing over this part, so you may have to google for help on these steps. So to use this module we need to install and setup Ubuntu on our VM. I used these steps to run an Ubuntu VM running in Virtual Box. You could totally skip this step if you already have a VM running, or want use an AWS VM or something
1. Virtual Box allows you to run Virtual Machines on your laptop/Desktop fairly easily. Download it here: https://www.virtualbox.org/wiki/Downloads
1. Download the Ubuntu 16.04 ISO file from here: http://releases.ubuntu.com/16.04/
1. Create a new VM  **(Set the network type to 'Bridged' in the networking tab in the VM settings.)** and install Ubuntu on it. The instructions for doing this are beyong the scope of this guide.  
1. Once it's installed, open a terminal window in the VM update the VM:
    ```
    sudo apt-get update
    sudo apt-get upgrade
    ```
1. Install virtual box guest addons and enable bidirectional copy-paste clipboard (hint: https://askubuntu.com/a/792833)

## Installing and setting up Puppet on your Ubuntu Box

Once you have the VM up and running and have the copy/paste working between your host and the VM then we can do the fun part!

1. First we want to do all of this as root, so do:
    ```
    sudo -i
    ```
1. We need to add the Offical Puppet Repos to our VM, as the ones managed by Ubuntu are outdated. so do:
    ```
    wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
    dpkg -i puppetlabs-release-pc1-xenial.deb
    apt-get update
    ```
1. Now we can install Puppet. So we do:
    ```
    apt-get install puppetserver
    ```
1. Now we need to add puppet to our PATH. So we do:
    ```
    echo 'export PATH=$PATH:/opt/puppetlabs/bin' >> .bashrc
    source .bashrc
    ```
1. Next up we need to add puppet to our hosts file so as not confuse the poor thing. So open the hosts file with (**Pro-tip learn to use Vi before running this:** https://www.howtogeek.com/102468/a-beginners-guide-to-editing-text-files-with-vi/):
    ```
    vi /etc/hosts
    ```
    Then we need to update the file to have the puppet master as 127.0.0.1 . So we add the word 'puppet' after where it says 'localhost'. Mine looks like this:
    ```
    127.0.0.1       localhost puppet
    127.0.1.1       test-VirtualBox
    
    # The following lines are desirable for IPv6 capable hosts
    ::1     ip6-localhost ip6-loopback
    fe00::0 ip6-localnet
    ff00::0 ip6-mcastprefix
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouters
    ```
1. Then we make sure the puppet master is running:
    ```
    puppet master
    ```
1. This means we can now link our agent to the master, to do that we run: 
    ```
    puppet agent -t
    ```
    Then you should see something like:
    ```
    Info: Using configured environment 'production'
    Info: Retrieving pluginfacts
    Info: Retrieving plugin
    Info: Caching catalog for virtualbox-vm
    Info: Applying configuration version '1508773742'
    ```
1. finally we just need to create a site.pp file. To do that we run:
    ```
    vi /etc/puppetlabs/code/environments/production/manifests/site.pp
    ```
    The file should be empty, so we need to make it look like this:
    ```
    node default {
    
    }
    ```
    
## Getting and using belet_seri

Now we have puppet installed and ready to do we can make use of this module. 

1. First up we gotta install the depencies. Which is easy enough. We go to the modules directory:

    ```
    cd /etc/puppetlabs/code/environments/production/modules/
    ```
    Then install the parts we need:
    ```
    apt-get install -f git
    puppet module install puppet-nginx
    puppet module install puppetlabs-mysql
    puppet module install puppetlabs-apt
    ```
1. Now we get the module itself:
    ```
    git clone https://github.com/puppetlabs/belet_seri.git  
    ```
1. Then we modify our site.pp file to include the module:
   ```
   vi /etc/puppetlabs/code/environments/production/manifests/site.pp
   ```
   Make it look like this:
   ```
    node default {
      class { 'belet_seri': }
    }
    ```
1. That means we can run puppet again it will install ALL THE THINGS!
    ```
    puppet agent -t
    ```
    this may take a wee while to run....
1. Done! At this point it's **should** bet set up..

## Testing it's ALIVE!?

1. Install curl:
    ```
    apt-get install curl
    ```
1. Get the fully qualified domain name for the VM using facter (facter is part of puppet)
    ```
    facter fqdn
    ```
1. Then we curl the domain name (the address returned by the line above):
    ```
    curl test-virtualbox
    ```

You can also enter the address into the browser on your laptop and see the result.

The endpoints are:
```
/
/names/
/names/<search term>
/add/<name you want to add>
```

So in my example:
```
root@test-VirtualBox:~# curl test-VirtualBox/names
{"names":["andy", "barry"]}
root@test-VirtualBox:~# curl test-VirtualBox/names/a
{"names":["andy"]}
```
