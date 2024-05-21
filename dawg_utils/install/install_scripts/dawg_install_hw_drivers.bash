#!/bin/bash

# Need to reboot after running this script

# Set ROS_IP
OS = "$1"
HOUND = "$2"
if [[ "$OS" == "aarch64" ]]; then
    echo "export ROS_IP=\$(ifconfig wlan0 | grep 'inet ' | awk '{print \$2}')" >> ~/.bashrc
else
    echo "export ROS_IP=\$(ifconfig \$(ifconfig | awk '/^[a-zA-Z]/{interface=$1} END{print interface}' | sed 's/://') | grep 'inet ' | awk '{print \$2}')" >> ~/.bashrc
    conda install -c conda-forge rospkg
    pip uninstall numpy
    pip install numpy==1.22.3 ## reinstall the correct version
fi

if [[ "$DAWG" == 1 ]]; then
	echo 'export PYTHONPATH="${PYTHONPATH}:/root/catkin_ws/src/BeamNGRL"' >> ~/.bashrc
fi
echo "ldconfig" >> ~/.bashrc

# Install BLDC tool. Following commands adapted from:
# https://github.com/jetsonhacks/installBLDC/blob/master/installBLDC.sh
# cd $ROOT
# apt-get install -y qtcreator libudev-dev libqt5serialport5-dev 
# git clone https://github.com/vedderb/bldc-tool
# cd bldc-tool
# qmake -qt=qt5
# make clean & make

# Install push-button drivers
# pip install Jetson.GPIO -y
# rm /usr/bin/python
# ln -s /usr/bin/python3 /usr/bin/python