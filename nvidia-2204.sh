#!/usr/bin/env bash

# Author: jithuantony4u@gmail.com
# Description: This script is support only ubuntu OS.
# Script to install nvidia driver, cudNN driver, container toolkit.

# Color definitions
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# ubuntu version
UBUNTU_VERSION="ubuntu2204"

# Check the system architecture
ARCHITECTURE=$(uname -m)

# Variables
NVIDIA_DRIVER_PIN_URL="https://developer.download.nvidia.com/compute/cuda/repos/${UBUNTU_VERSION}/x86_64/cuda-${UBUNTU_VERSION}.pin"
NVIDIA_DRIVER_PIN_FILE="cuda-${UBUNTU_VERSION}.pin"
NVIDIA_DRIVER_PIN_DEST="/etc/apt/preferences.d/cuda-repository-pin-600"
CUDA_REPO_URL="https://developer.download.nvidia.com/compute/cuda/12.6.1/local_installers/cuda-repo-${UBUNTU_VERSION}-12-6-local_12.6.1-560.35.03-1_amd64.deb"
CUDA_REPO_FILE="cuda-repo-${UBUNTU_VERSION}-12-6-local_12.6.1-560.35.03-1_amd64.deb"
CUDA_KEYRING_SRC="/var/cuda-repo-${UBUNTU_VERSION}-12-6-local/cuda-*-keyring.gpg"
CUDA_KEYRING_DEST="/usr/share/keyrings/"
CUDA_TOOLKIT="cuda-toolkit-12-6"
CUDA_PATH_EXPORT1='export PATH=/usr/local/cuda-12.6/bin${PATH:+:${PATH}}'
CUDA_PATH_EXPORT2='export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}'
CUDNN_URL="https://developer.download.nvidia.com/compute/cudnn/9.4.0/local_installers/cudnn-local-repo-${UBUNTU_VERSION}-9.4.0_1.0-1_amd64.deb"
CUDNN_FILE="cudnn-local-repo-${UBUNTU_VERSION}-9.4.0_1.0-1_amd64.deb"
CUDNN_KEYRING_SRC="/var/cudnn-local-repo-${UBUNTU_VERSION}-9.4.0/cudnn-*-keyring.gpg "
NVIDIA_CONTAINER_TOOLKIT_GPGKEY_URL="https://nvidia.github.io/libnvidia-container/gpgkey"
NVIDIA_CONTAINER_TOOLKIT_LIST_URL="https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list"
NVIDIA_CONTAINER_TOOLKIT_LIST_FILE="/etc/apt/sources.list.d/nvidia-container-toolkit.list"
NVIDIA_CONTAINER_TOOLKIT="nvidia-container-toolkit"

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}ERROR: This script must be run as root or with sudo.${NC}"
  exit 1
fi

# Check if the architecture is x86_64
if [ "$ARCHITECTURE" == "x86_64" ]; then
    echo -e "${YELLOW}INFO: Architecture is x86_64, continuing...${NC}"
else
    echo -e "${RED}ERROR: Unsupported architecture: $ARCHITECTURE, exiting...${NC}"
    exit 1
fi

# Update and install initial packages
echo -e "${YELLOW}INFO: Updating package lists...${NC}"
{
    sudo apt update -y -qq > /dev/null 2>&1 && echo -e "${GREEN}SUCCESS: Package lists updated.${NC}"
} || {
    echo -e "${RED}ERROR: Failed to update package lists${NC}"
    exit 1
}

echo -e "${YELLOW}INFO: Installing curl and wget...${NC}"
{
    sudo apt install curl wget -y -qq > /dev/null 2>&1 && echo -e "${GREEN}SUCCESS: curl and wget installed.${NC}"
} || {
    echo -e "${RED}ERROR: Failed to install curl and wget${NC}"
    exit 1
}

# Check if NVIDIA driver is already installed
if command -v nvidia-smi &> /dev/null; then
    echo -e "${YELLOW}INFO: NVIDIA driver already installed. Skipping driver installation.${NC}"
else
    # NVIDIA & CUDA driver installation
    echo -e "${YELLOW}INFO: NVIDIA driver installing.....${NC}"
    {
        wget -q $NVIDIA_DRIVER_PIN_URL > /dev/null 2>&1 &&
        sudo mv $NVIDIA_DRIVER_PIN_FILE $NVIDIA_DRIVER_PIN_DEST > /dev/null 2>&1 &&
        wget -q $CUDA_REPO_URL > /dev/null 2>&1 &&
        sudo dpkg -i $CUDA_REPO_FILE > /dev/null 2>&1 &&
        sudo cp $CUDA_KEYRING_SRC $CUDA_KEYRING_DEST > /dev/null 2>&1 &&
        sudo apt update -y -qq > /dev/null 2>&1 &&
        sudo apt install $CUDA_TOOLKIT nvidia-kernel-open-560 cuda-drivers-560 -y -qq > /dev/null 2>&1 &&
        echo -e "${GREEN}SUCCESS: NVIDIA driver and CUDA toolkit installed.${NC}"
    } || {
        echo -e "${RED}ERROR: Failed to install NVIDIA driver and CUDA toolkit${NC}"
        exit 1
    }

    # CUDA path export
    echo -e "${YELLOW}INFO: Exporting CUDA paths...${NC}"
    {
        echo $CUDA_PATH_EXPORT1 >> /home/ubuntu/.bashrc &&
        echo $CUDA_PATH_EXPORT2 >> /home/ubuntu/.bashrc &&
        echo -e "${GREEN}SUCCESS: CUDA paths exported.${NC}" &&
        echo -e "${YELLOW}INFO: Lines added to /home/ubuntu/.bashrc${NC}"
    } || {
        echo -e "${RED}ERROR: Failed to export CUDA paths${NC}"
        exit 1
    }
fi

# Check if cuDNN is already installed
echo -e "${YELLOW}INFO: Checking if cuDNN is already installed...${NC}"
if sudo dpkg -l | grep -q cudnn-local-repo-ubuntu2204-8.9.6.50; then
    echo -e "${YELLOW}INFO: cuDNN already installed. Skipping cuDNN installation.${NC}"
else
    # cuDNN install
    echo -e "${YELLOW}INFO: Installing cuDNN...${NC}"
    {
        wget -q $CUDNN_URL > /dev/null 2>&1 &&
        sudo dpkg -i $CUDNN_FILE > /dev/null 2>&1 &&
        sudo cp $CUDNN_KEYRING_SRC $CUDA_KEYRING_DEST > /dev/null 2>&1 &&
        sudo apt-get update -qq > /dev/null 2>&1 &&
        sudo apt-get install cudnn -y -qq > /dev/null 2>&1 &&
        echo -e "${GREEN}SUCCESS: cuDNN installed.${NC}"
    } || {
        echo -e "${RED}ERROR: Failed to install cuDNN${NC}"
        exit 1
    }
fi

# Check if NVIDIA container toolkit is already installed
if command -v nvidia-container-runtime &> /dev/null; then
    echo -e "${YELLOW}INFO: NVIDIA container toolkit already installed. Skipping container toolkit installation.${NC}"
else
    # Container toolkit install
    echo -e "${YELLOW}INFO: Installing NVIDIA container toolkit...${NC}"
    {
        curl -fsSL $NVIDIA_CONTAINER_TOOLKIT_GPGKEY_URL | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg > /dev/null 2>&1 &&
        sudo curl -s -L $NVIDIA_CONTAINER_TOOLKIT_LIST_URL | sudo sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee $NVIDIA_CONTAINER_TOOLKIT_LIST_FILE > /dev/null 2>&1 &&
        sudo sed -i -e '/experimental/ s/^#//g' $NVIDIA_CONTAINER_TOOLKIT_LIST_FILE > /dev/null 2>&1 &&
        sudo apt update -y -qq > /dev/null 2>&1 &&
        sudo apt install $NVIDIA_CONTAINER_TOOLKIT -y -qq > /dev/null 2>&1 &&
        sudo nvidia-ctk runtime configure --runtime=docker > /dev/null 2>&1 &&
        sudo nvidia-smi -pm 1 > /dev/null 2>&1 &&
        echo -e "${GREEN}SUCCESS: NVIDIA container toolkit installed and configured.${NC}"
    } || {
        echo -e "${RED}ERROR: Failed to install NVIDIA container toolkit${NC}"
        exit 1
    }
fi

# Check if the cron job already exists
if ! crontab -l | grep -q "@reboot sudo nvidia-smi -pm 1"; then
    # Add the cron job to run on reboot
    (crontab -l; echo "@reboot sudo nvidia-smi -pm 1") | crontab -
    echo -e "${YELLOW}INFO: Cron job added to enable NVIDIA persistence mode at reboot.${NC}"
else
    echo -e "${YELLOW}INFO: Cron job already exists.${NC}"
fi

# Final message and countdown before reboot
echo -e "${GREEN}Kernel modules installed. Rebooting the machine in 10 seconds...${NC}"
for i in {10..1}; do
    echo -e "${YELLOW}Rebooting in $i...${NC}"
    sleep 1
done

# Reboot the machine
sudo init 6