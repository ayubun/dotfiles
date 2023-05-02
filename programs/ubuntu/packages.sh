#!/bin/bash

# This script attempts to install all "essential" (for me :3) packages on Ubuntu

sudo apt-get update -y
sudo apt-get upgrade -y

sudo apt-get install build-essential -y
sudo apt-get install manpages-dev -y
sudo apt-get install dnsutils -y
sudo apt-get install neofetch -y
sudo apt-get install google-cloud-sdk-pubsub-emulator -y
sudo apt-get install net-tools -y

# python 3.8
# sudo apt install software-properties-common -y
# sudo add-apt-repository ppa:deadsnakes/ppa -y 
# sudo apt update -y 
# sudo apt install python3.8

# cleanup
# sudo apt update -y
# sudo apt upgrade -y
# sudo apt --fix-broken install -y 
# sudo apt autoremove -y