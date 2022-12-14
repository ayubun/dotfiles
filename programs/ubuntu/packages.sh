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
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa -y 
sudo apt update -y 
sudo apt install python3.8

# gcloud cli
sudo apt-get install apt-transport-https ca-certificates gnupg -y &> /dev/null
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list &> /dev/null
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - &> /dev/null
sudo apt-get update -y &> /dev/null
sudo apt-get install google-cloud-cli -y &> /dev/null
sudo apt-get install google-cloud-cli-cbt -y &> /dev/null

sudo apt autoremove -y
