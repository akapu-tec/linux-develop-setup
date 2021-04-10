# Install E-SUS Server
# Ubuntu 20.04
# Author: Gedean Dias
# Date: 01-2021

### WSL Setup
# wsl -l -v
# wsl --set-version <distriubtion name> <version number>
# e.g.
# wsl --set-version Ubuntu-20.04 2


### Ubuntu
sudo apt update

# Intall Java
# sudo apt install openjdk-8-jre-headless
sudo apt-get install openjdk-8-jre


# https://phoenixnap.com/kb/how-to-install-a-gui-on-ubuntu
sudo apt-get install tasksel
sudo apt-get install slim


# To install GNOME, start by launching tasksel:
## Select "Ubuntu Desktop" with "space" key

sudo tasksel
