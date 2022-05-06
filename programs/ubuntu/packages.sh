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

sudo apt autoremove -y
