#!/bin/bash

CURRENT_DIR=$(pwd)
cd $HOME/dotfiles/tmp

# https://github.com/fullstorydev/grpcurl
VERSION=1.8.7
mkdir grpcurl  # Temp dir for this binary
curl -L "https://github.com/fullstorydev/grpcurl/releases/download/v${VERSION}/grpcurl_${VERSION}_linux_x86_64.tar.gz" | tar xz -C grpcurl
sudo mv -f grpcurl/grpcurl /usr/bin/
sudo rm -rf grpcurl  # Remove temp dir

cd $CURRENT_DIR