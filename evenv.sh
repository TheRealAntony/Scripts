#!/usr/bin/env bash

# Author: jithuantony4u@gmail.com
# Description: This script is support only ubuntu OS.
# Script to deploy kvm vms

# set -x
# set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PREFIX=ebuild

# vm constants
VM_DIR="$HOME/libvirt-vms"
VM_NAME=${PREFIX}-vm
VM_CPU=4
VM_RAM=6144 # 6GB
VM_NUM=1
VM_CFG_FILE="user_config.txt"
VM_USER_NAME="ubuntu"
VM_USER_PWD="ubuntu"

# net constants
NET_DIR="$HOME/libvirt-vms"
NET_NAME=${PREFIX}-vcnet
NET_NUM=1

# image constants
IMAGE_DIR="$HOME/libvirt-vms"
IMAGE_DISTRO="24.04"
IMAGE_RELEASE_NAME="noble"
IMAGE_NAME="ubuntu-${IMAGE_DISTRO}-minimal-cloudimg-amd64.img"
IMAGE_URL="https://cloud-images.ubuntu.com/minimal/releases/${IMAGE_RELEASE_NAME}/release/${IMAGE_NAME}"

# disk sizes in GB
OS_DISK_SIZE=30
DATA_DISK_SIZE=10

clean-image() {
  echo -e "${YELLOW}Cleaning image:${IMAGE_NAME}${NC}..."
  sudo rm ${IMAGE_DIR}/${IMAGE_NAME} 2> /dev/null
  echo -e "${YELLOW}Cleaned image:${IMAGE_NAME}${NC}"
}

resize-image() {
  echo -e "${YELLOW}Resizing image ${IMAGE_NAME}${NC} to ${OS_DISK_SIZE}G..."
  sudo qemu-img resize ${IMAGE_DIR}/${IMAGE_NAME} ${OS_DISK_SIZE}G
}

download-image() {
  clean-image

  # ensure the image directory exists
  mkdir -p ${IMAGE_DIR}
  sudo chown -R libvirt-qemu:kvm ${IMAGE_DIR}/*

  echo -e "${YELLOW}Downloading image ${IMAGE_NAME}${NC}..."
  wget ${IMAGE_URL} --show-progress
  sudo mv ${IMAGE_NAME} ${IMAGE_DIR}
  sudo chown -R libvirt-qemu:kvm ${IMAGE_DIR}/*
  echo -e "${GREEN}Downloaded image ${IMAGE_NAME}${NC}"

  resize-image
}

clean-net() {
  echo -e "${YELLOW}Cleaning networks($NET_NUM)${NC}..."

  for i in $( seq 1 $NET_NUM )
  do
    net_name=${NET_NAME}-$i
    echo -e "${YELLOW}Cleaning network:${net_name}${NC}..."
    sudo virsh net-destroy ${net_name} 2> /dev/null
    sudo virsh net-undefine ${net_name} 2> /dev/null
    sudo rm ${NET_DIR}/${net_name}-network.xml 2> /dev/null
    sleep 3
    echo -e "${GREEN}Cleaned network:${net_name}${NC}"
  done
}

create-net() {
  clean-net

  # ensure the net directory exists
  mkdir -p "${NET_DIR}"
  sudo chown -R libvirt-qemu:kvm ${NET_DIR}/*

  for i in $(seq 1 $NET_NUM); do
    net_name=${NET_NAME}-$i
    echo -e "${YELLOW}Creating network:${net_name}${NC}..."

    net_file=${NET_DIR}/${net_name}-network.xml
    generate_net_config "$i" > "network-${i}.xml"
    sudo mv network-$i.xml ${net_file}
    sudo chown libvirt-qemu:kvm "${net_file}"
    sudo virsh net-define "${net_file}"
    sudo virsh net-start "${net_name}"
    echo -e "${GREEN}Created network:${net_name}${NC}"
  done
  sudo iptables --flush
}

generate_net_config() {
  local i=$1
  cat <<EOF
<network connections='2'>
  <name>ebuild-vcnet-$i</name>
  <uuid>$(uuidgen)</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <mac address='$(generate_vm_mac)'/>
  <ip address='$(generate_vm_ip "$i")' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.$((100+i)).1.50' end='10.$((100+i)).1.100'/>
    </dhcp>
  </ip>
</network>
EOF
}

generate_vm_config() {
  cat <<EOF
#cloud-config
user: ubuntu
password: ubuntu
chpasswd: { expire: False }
ssh_pwauth: True
ssh_authorized_keys:
EOF
}

generate_vm_mac() {
  printf "02:ec:3d:39:84:%02x\n" $((RANDOM%256))
}

generate_vm_ip() {
  local count=$1
  printf "10.$((100+count)).1.%d\n" $((1))
}

clean-vm() {
  for i in $( seq 1 $VM_NUM )
  do
    vm_name=${VM_NAME}-$i
    echo -e "${YELLOW}Cleaning machine:${vm_name}${NC}..."
    sudo virsh destroy ${vm_name} 2> /dev/null
    sudo virsh undefine ${vm_name} 2> /dev/null
    echo -e "${GREEN}Cleaned machine:${vm_name}${NC}"

    user_disk=${VM_DIR}/${PREFIX}-user-data-$i.img
    sudo rm ${user_disk} 2> /dev/null

    data_disk=${IMAGE_DIR}/${PREFIX}-data-$i.qcow2
    echo -e "${YELLOW}Cleaning data_disk:${data_disk}${NC}..."
    sudo rm ${data_disk} 2> /dev/null
    echo -e "${GREEN}Cleaned data_disk:${data_disk}${NC}"
    
    os_disk=${IMAGE_DIR}/${PREFIX}-os-$i.qcow2
    echo -e "${YELLOW}Cleaning os_disk:${os_disk}${NC}..."
    sudo rm ${os_disk} 2> /dev/null
    echo -e "${GREEN}Cleaned os_disk:${os_disk}${NC}"

    sleep 3
  done
  sudo rm ${VM_DIR}/${VM_CFG_FILE} 2> /dev/null
}

enable-ssh() {
  local ip=$1
  echo -e "${YELLOW}Enabling passwordless ssh access for ${ip} ${NC}..."
  ssh-keyscan -H ${ip} >>  ~/.ssh/known_hosts  > /dev/null 2>&1
  sshpass -p ${VM_USER_NAME} ssh-copy-id -o StrictHostKeyChecking=no ${VM_USER_NAME}@${ip} > /dev/null 2>&1
	echo -e "${GREEN}Enabled passwordless ssh access${NC}"
}

create-vm() {
  clean-vm

  # ensure the vm directory exists
  mkdir -p "${VM_DIR}"
  sudo chown -R libvirt-qemu:kvm ${VM_DIR}/*

  # prepare network list
  vm_nets=""
  for i in $( seq 1 $NET_NUM )
  do
    vm_nets+="--network network=${NET_NAME}-${i} "
  done

  # prepare cloud init configuration
  generate_vm_config > ${VM_CFG_FILE}

  # add host ssh public key to the user data
  echo -n '  - ' >> ${VM_CFG_FILE}
  tr -d '' < ~/.ssh/id_rsa.pub >> ${VM_CFG_FILE}

  for i in $( seq 1 $VM_NUM )
  do
    os_disk=${VM_DIR}/${PREFIX}-os-$i.qcow2
    echo -e "${YELLOW}Creating os disk of size ${OS_DISK_SIZE}G${NC}..."
    sudo cp ${IMAGE_DIR}/${IMAGE_NAME} ${os_disk}
    sudo chown -R libvirt-qemu:kvm ${VM_DIR}/*
    echo -e "${GREEN}Prepared os disk:${os_disk}${NC}"

    user_disk=${VM_DIR}/${PREFIX}-user-data-$i.img
    sudo cloud-localds ${user_disk} user_config.txt
    sudo chown -R libvirt-qemu:kvm ${VM_DIR}/*
    
    data_disk=${VM_DIR}/${PREFIX}-data-$i.qcow2
    echo -e "${YELLOW}Creating data disk of size ${DATA_DISK_SIZE}G${NC}..."
    sudo qemu-img create -o preallocation=full -f qcow2 ${data_disk} ${DATA_DISK_SIZE}G 2> /dev/null
    sudo chown -R libvirt-qemu:kvm ${VM_DIR}/*
    echo -e "${GREEN}Prepared data disk:${data_disk}${NC}"

    vm_name=${VM_NAME}-$i
    echo -e "${YELLOW}Deploying ${vm_name} machine with networks:${vm_nets}${NC}"
    virt-install --connect \
      qemu:///system \
      --import \
      --name ${vm_name} \
      --memory ${VM_RAM} \
      --vcpus ${VM_CPU} \
      --cpu host \
      --disk path=$os_disk,bus=virtio,format=qcow2,size=${OS_DISK_SIZE} \
      --os-variant=ubuntu${IMAGE_DISTRO} \
      ${vm_nets} \
      --disk ${user_disk} \
      --disk ${data_disk} \
      --nographics & 2> /dev/null \

    sudo chown -R libvirt-qemu:kvm ${VM_DIR}/*
    echo -e "${YELLOW}Waiting for ${vm_name} to be created${NC}..."
    sleep 10
  done
  sudo mv ${VM_CFG_FILE} ${VM_DIR}/${VM_CFG_FILE}
  sudo chown -R libvirt-qemu:kvm ${VM_DIR}/*

  echo -e "${YELLOW}Waiting for ($VM_NUM) vms to acquire an ip address${NC}..."
  for i in {1..15}
  do
    all_got_ip=true
    for j in $( seq 1 $VM_NUM )
    do
      vm_name=${VM_NAME}-$j
      IP=$(sudo virsh -q domifaddr ${vm_name} | awk '{ print $4 }' | sed 's/\/.*//g')
      if [[ -n "$IP" ]]; then
        echo -e "${GREEN}${vm_name} has got an ip address:${IP}${NC}"
        echo -e "${YELLOW}Login using bash command: sshpass -p "${VM_USER_PWD}" ssh ${VM_USER_NAME}@${IP}${NC}"
        enable-ssh "$IP"
      else
        echo -e "${BLUE}${vm_name} has not got an ip address yet, will retry after 15s${NC}"
        all_got_ip=false
      fi
    done

    if $all_got_ip; then
      break
    fi

    # wait for ip availability check
    sleep 15
  done
}

while getopts ":u:s:d:" opt  ${@:2}; do
  case $opt in
    u)
      IMAGE_URL=$OPTARG
      ;;
    s)
      OS_DISK_SIZE=$OPTARG
      ;;
    d)
      DATA_DISK_SIZE=$OPTARG  
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

help () {
  echo -e "
\e${GREEN}Script to deploy a virtual environment which can be used to build custom images${NC}.
${YELLOW}Image commands${NC}:
  download    download image
    -u url    ubuntu image url (default to $IMAGE_URL)
    -s size   image size in GB (default to ${OS_DISK_SIZE}GB)
  clean       cleans downloaded image

${YELLOW}VM commands${NC}:
  deploy      deploy virtual machines
    -d size   data disk size in GB (default to ${DATA_DISK_SIZE}GB)
  destroy     destroys deployed virtual machines
  "
}

case $1 in
  clean)
    clean-image
  ;;
  download)
    download-image
  ;;
  deploy)
    if [ -e "${IMAGE_DIR}/${IMAGE_NAME}" ]; then
      create-net
      create-vm
    else
      echo -e "\e${RED}Make sure to download image before deploying virtual machines${NC}"
    fi
  ;;
  destroy)
    clean-vm
    clean-net
  ;;
  *)
    help
  ;;
esac

exit 0