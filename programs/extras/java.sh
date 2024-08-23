#!/bin/bash

CURRENT_DIR=$(pwd)

# Clean any old Java installations
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Remove old JDK(s) / alternatives
    sudo rm -rf /usr/lib/jvm
    sudo rm -rf /usr/java
    sudo update-alternatives --remove-all java
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Remove old JDK(s)
    sudo find -E /Library/Java/JavaVirtualMachines -mindepth 1 -maxdepth 1 -type d \
        -regex '.*.jdk$' \
        -exec rm -rf {} +
fi

# Make a temp directory and curl JDK
JDK_VERSION="22.0.2"

mkdir $HOME/dotfiles/tmp &>/dev/null
cd $HOME/dotfiles/tmp
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    INSTALL_OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    INSTALL_OS="macos"
fi
# Likely have to update this because of the hash in the URL
curl -O "https://download.java.net/java/GA/jdk${JDK_VERSION}/c9ecb94cd31b495da20a27d4581645e8/9/GPL/openjdk-${JDK_VERSION}_${INSTALL_OS}-x64_bin.tar.gz"
tar xvf "openjdk-${JDK_VERSION}_${INSTALL_OS}-x64_bin.tar.gz"

# Apply the installation (OS-specific)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo mkdir /usr/java
    sudo mv "jdk-${JDK_VERSION}" "/usr/java/jdk-${JDK_VERSION}"
    # stackoverflow answer: https://stackoverflow.com/questions/11237872/java-command-not-found-on-linux
    export JAVA_BIN_DIR="/usr/java/jdk-${JDK_VERSION}/bin"
    cd ${JAVA_BIN_DIR}
    a=(java javac javadoc javap)
    for exe in ${a[@]}; do
        sudo update-alternatives --install "/usr/bin/${exe}" "${exe}" "${JAVA_BIN_DIR}/${exe}" 1
        sudo update-alternatives --set ${exe} ${JAVA_BIN_DIR}/${exe}
    done
elif [[ "$OSTYPE" == "darwin"* ]]; then
    sudo mv "jdk-${JDK_VERSION}.jdk" /Library/Java/JavaVirtualMachines/
fi

cd $CURRENT_DIR
