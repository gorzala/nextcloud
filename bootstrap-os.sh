#!/bin/bash

# Author: Marc Gorzala
# Iam using this script on freshly created servers of my
# cloud provider to install something like the following
#
# * git
# * docker
# * docker-compose
# just everything to enable me to start the nextcloud compose project
#
# You can have this script as a guid what you have to do installing the 
# needed tools.
# You can even give the script a try to and invoke it on a virgin
# debian based machine.
# If you are lucky, fine! If not, just reproduce what this script 
# is intended to do.


# 1) Update package-database and upgrade base system
sudo apt -y update
sudo apt -y dist-upgrade

# 2) Install docker
sudo curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# 3) Install docker compose
sudo apt -y install python3
sudo apt -y install python3-setuptools
sudo apt -y install python3-pip
sudo pip3 install docker-compose

# 4) Install git
sudo apt -y install git

# 5) Vim is always good to have ;-)
sudo apt -y install vim

# 6) Clone dat repo that configures all
mkdir /root/
git clone https://github.com/gorzala/nextcloud.git
