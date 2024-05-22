#!/bin/bash
pushd `dirname $0`

# Detect OS 
export DAWG_OS_TYPE="$(uname -s)"

# Are we in the right place to be running this?
if [[ ! -f dawg_install.bash ]]; then
  echo Wrong directory! Change directory to the one containing dawg_install.bash
  exit 1
fi
export DAWG_INSTALL_PATH=$(pwd)

# Real robot or on a laptop?
read -p "Are you installing on robot and need all the sensor drivers? (y/n) " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    export DAWG_REAL_ROBOT=1
    export DAWG_COMPOSE_FILE=docker-compose-robot.yml
else
    export DAWG_REAL_ROBOT=0
    export DAWG_COMPOSE_FILE=docker-compose-cpu.yml
fi


# Build from scratch 
read -p "Build from scratch? (Not recommended, takes much longer than pulling ready-made image) (y/n) " -r
echo
export BUILD_FROM_SCRATCH=0
if [[ $REPLY =~ ^[Yy]$ ]]; then
  export BUILD_FROM_SCRATCH=1
  if [[ $DAWG_REAL_ROBOT == 1 ]]; then
  	export DAWG_COMPOSE_FILE=docker-compose-build-robot.yml
  else
  	export DAWG_COMPOSE_FILE=docker-compose-build-cpu.yml
  fi
fi

# curl and dep keys
if [[ $DAWG_OS_TYPE == "Linux" ]]; then
  sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
  sudo apt-get update
  sudo apt-get install -y curl
  curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -

  # Reset to specific hardware
  export DAWG_OS_TYPE="$(uname -i)"
fi

if [ "$DAWG_OS_TYPE" = "x86_64" ]; then
    export DAWG_BASE_IMAGE="ubuntu:20.04"
elif [ "$DAWG_OS_TYPE" = "aarch64" ]; then
    export DAWG_BASE_IMAGE="ubuntu:20.04"
else
    echo "Unknown OS type: $DAWG_OS_TYPE"
    exit 0
fi

# Robot specific settings
if [[ $DAWG_REAL_ROBOT == 1 ]]; then
    echo Running robot specific commands
    
    # Don't need sudo for docker
    sudo usermod -aG docker $USER
    
    # docker-compose
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.2.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

    # # Need to connect to ydlidar
    # git clone https://github.com/prl-mushr/ydlidar
    # cd ydlidar
    # sudo sh startup/initenv.sh
    # cd .. && rm -rf ydlidar

    # # Setup VESC udev rules. Following commands adapted from:
    # # https://github.com/RacecarJ/installRACECARUdev
    # echo "ACTION==\"add\", ATTRS{idVendor}==\"0483\", ATTRS{idProduct}==\"5740\", SYMLINK+=\"vesc\"" > /tmp/10-vesc.rules
    # sudo mv /tmp/10-vesc.rules /etc/udev/rules.d/
    # sudo udevadm control --reload-rules && udevadm trigger

    # # Install GPIO library
    # pip install Jetson.GPIO
    # sudo groupadd -f -r gpio
    # sudo usermod -a -G gpio $USER
    # sudo wget https://raw.githubusercontent.com/NVIDIA/jetson-gpio/master/lib/python/Jetson/GPIO/99-gpio.rules -O /etc/udev/rules.d/99-gpio.rules
    # sudo udevadm control --reload-rules && udevadm trigger

    # # Setup rc.local
    # echo '#!/bin/sh -e' > /tmp/rc.local
    # echo "echo 200 > /sys/class/gpio/export" >> /tmp/rc.local
    # echo "chmod go+w /sys/class/gpio/gpio200/direction" >> /tmp/rc.local
    # echo "chmod go+rw /sys/class/gpio/gpio200/value" >> /tmp/rc.local
    # echo "echo \"in\" > /sys/class/gpio/gpio200/direction" >> /tmp/rc.local
    # echo "rs-enumerate-devices &> /dev/null" >> /tmp/rc.local
    # echo "nvpmodel -m 0" >> /tmp/rc.local
    # echo "sleep 60 && jetson_clocks" >> /tmp/rc.local
    # sudo mv /tmp/rc.local /etc/rc.local

    # Setup docker base image and mushr self start service
    sudo usermod -aG docker $USER
    sudo cp ~/catkin_ws/src/dawg/daemon.json /etc/docker/daemon.json
    ## add mushr_start.service to services (where?)
    sudo cp ~/catkin_ws/src/dawg/dawg_utils/install/dawg_start.service /etc/systemd/system
    sudo systemctl enable dawg_start.service
fi

# vcstool https://github.com/dirk-thomas/vcstool 
if [[ $DAWG_OS_TYPE != "Darwin" ]]; then
  sudo apt-get update && sudo apt install -y python3-vcstool
else
  pip install vcstool
fi

# Pull repos
export DAWG_WS_PATH=$(echo $DAWG_INSTALL_PATH | sed 's:/catkin_ws.*::')
# cd $DAWG_WS_PATH/catkin_ws/src/ && vcs import < dawg/base-repos.yaml && vcs import < dawg/nav-repos.yaml && if [[ $HOUND = 1 ]]; then vcs import < dawg/hound_repos.yaml; fi

# Make custom dawg_noetic script
cat <<- EOF > ${DAWG_INSTALL_PATH}/dawg_noetic
export DAWG_INSTALL_PATH=${DAWG_INSTALL_PATH}
export DAWG_REAL_ROBOT=${DAWG_REAL_ROBOT}
export DAWG_WS_PATH=${DAWG_WS_PATH}
export DAWG_COMPOSE_FILE=${DAWG_COMPOSE_FILE}
export DAWG_OS_TYPE=${DAWG_OS_TYPE}
export DAWG_BASE_IMAGE=${DAWG_BASE_IMAGE}

xhost +local:docker
docker-compose -f \$DAWG_INSTALL_PATH/\$DAWG_COMPOSE_FILE run -p 9090:9090 --rm dawg_noetic bash
xhost -local:docker

# docker-compose -f \$DAWG_INSTALL_PATH/\$DAWG_COMPOSE_FILE run -p 9090:9090 -d --rm dawg_noetic /root/catkin_ws/src/hound_core/entry_command.sh
EOF
chmod +x ${DAWG_INSTALL_PATH}/dawg_noetic
sudo ln -s ${DAWG_INSTALL_PATH}/dawg_noetic /usr/local/bin/

# # If laptop, don't build realsense2_camera, ydlidar, or push_button_utils
# if [[ $DAWG_REAL_ROBOT == 0 ]]; then
#   for ignored_package in push_button_utils ydlidar; do
#     touch $dawg_WS_PATH/catkin_ws/src/dawg/dawg_hardware/${ignored_package}/CATKIN_IGNORE
#   done
# fi

# Make sure all devices are visible
if [[ $DAWG_REAL_ROBOT == 1 ]]; then
  sudo udevadm control --reload-rules && sudo udevadm trigger
fi
popd