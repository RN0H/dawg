ARG BASE_IMAGE
FROM "$BASE_IMAGE"

LABEL maintainer Rohan Panicker

ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /root

RUN apt-get update

RUN apt-get install software-properties-common -y

# Install docker deps for dawg_install 
RUN apt-get update -y \
    && apt-get install keyboard-configuration apt-utils gnupg2 curl -y \
    && apt-get update -y

# Adding/Running files separately allows us to cache
RUN mkdir install_scripts

# ROS Noetic
ADD src/dawg/dawg_utils/install/install_scripts/dawg_install_ros.bash install_scripts/dawg_install_ros.bash
RUN chmod +x install_scripts/dawg_install_ros.bash && install_scripts/dawg_install_ros.bash 

# Hardware drivers
# 1 = real robot, 0 = sim (laptop)
ARG OS
ARG DAWG

# Catkin build and other deps
ADD . catkin_ws

ADD src/dawg/dawg_utils/install/install_scripts/dawg_install_deps.bash install_scripts/dawg_install_deps.bash
RUN chmod +x install_scripts/dawg_install_deps.bash && install_scripts/dawg_install_deps.bash "$OS"

ADD src/dawg/dawg_utils/install/install_scripts/dawg_install_hw_drivers.bash install_scripts/dawg_install_hw_drivers.bash
RUN if [ "$DAWG" = 1 ] ; then chmod +x install_scripts/dawg_install_hw_drivers.bash && install_scripts/dawg_install_hw_drivers.bash "$OS" "$DAWG" ; fi

#Install Mavros
ADD src/dawg/dawg_utils/install/install_scripts/dawg_mavros_install.bash install_scripts/dawg_mavros_install.bash
RUN if [ "$DAWG" = 1 ] ; then chmod +x install_scripts/dawg_mavros_install.bash && install_scripts/dawg_mavros_install.bash ; fi