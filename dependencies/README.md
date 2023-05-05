
## Dependencies

This directory contains all scripts that are run at the beginning of `install.sh` so that the remainder of the scripts can execute with an
expectation that certain CLIs will be pre-installed. For example, GNU `parallel` is installed here so that it may be used to speed up the
installation process (on both Ubuntu and MacOS).

Package managers & any wrappers are also installed here (brew for MacOS and apt-fast for Ubuntu).