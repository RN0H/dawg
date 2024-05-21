#!/bin/bash


# Install vcstool, pip
sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
apt-key adv --keyserver hkp://pool.sks-keyservers.net --recv-key 0xAB17C654
apt-get update
apt-get install -y python3-vcstool python3-pip

# Install extra ROS packages
apt-get install -y ros-noetic-ackermann-msgs ros-noetic-map-server ros-noetic-urg-node ros-noetic-robot-state-publisher ros-noetic-xacro ros-noetic-joy ros-noetic-ddynamic-reconfigure  g ros-noetic-rosbridge-suite ros-noetic-sbpl

# Install catkin tools
wget http://packages.ros.org/ros.key -O - | apt-key add -
apt-get update
apt-get install -y python3-catkin-tools


pip install empy
pip install catkin-tools ## because apparently python3-catkin-tools != catkin-tools?


# Auto source this workspace on terminal startup
echo "source ~/catkin_ws/devel/setup.bash" >> ~/.bashrc