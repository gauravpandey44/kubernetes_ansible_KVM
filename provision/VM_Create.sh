#!/bin/bash


NETWORK_NAME=$1
NETWORK_FILE=/tmp/default.xml
PUB_KEY=$2
image_url=$3
download_image_name=$4
VM_USER=$5
HOST_USER=$6
VERSION=$7
VM_GATEWAY_ADDR=$8
VM_DHCP_START_ADDR=$9
VM_DHCP_END_ADDR=${10}
VM_NETMASK=${11}
VM_NETWORK_BRIDGE=${12}

#Storing data from files into array

HOSTS=`echo $(cat /tmp/hostnames_vm.out) | tr -s ',' ' '`
IP=`echo $(cat /tmp/ips_vm.out) | tr -s ',' ' '`
RAM=`echo $(cat /tmp/ram_vm.out) | tr -s ',' ' '`
DISK=`echo $(cat /tmp/disk_vm.out) | tr -s ',' ' '`
MACID=`echo $(cat /tmp/macid_vm.out) | tr -s ',' ' '`
CPU=`echo $(cat /tmp/cpu_vm.out) | tr -s ',' ' '`


IFS=', ' read -r -a HOSTS_array <<< $HOSTS
IFS=', ' read -r -a IP_array <<< $IP
IFS=', ' read -r -a RAM_array <<< $RAM
IFS=', ' read -r -a DISK_array <<< $DISK
IFS=', ' read -r -a MACID_array <<< $MACID
IFS=', ' read -r -a CPU_array <<< $CPU

no_of_vms=${#HOSTS_array[@]}
echo "No of VMs needs to be created are : $no_of_vms "

#Creating network for K8s
                                                                                
echo "<network>" >$NETWORK_FILE
echo "<name>$NETWORK_NAME</name>" >>$NETWORK_FILE
echo "<forward mode='nat'/>" >>$NETWORK_FILE
echo "<bridge name='$VM_NETWORK_BRIDGE' stp='on' delay='0'/>" >>$NETWORK_FILE
echo "<ip address='$VM_GATEWAY_ADDR' netmask='$VM_NETMASK'>" >>$NETWORK_FILE
echo "<dhcp>">>$NETWORK_FILE
echo "<range start='$VM_DHCP_START_ADDR' end='$VM_DHCP_END_ADDR'/>" >>$NETWORK_FILE

i=0
while [ $i -lt $no_of_vms ]
do
   echo "<host mac='${MACID_array[i]}' name='${HOSTS_array[i]}' ip='${IP_array[i]}'/>" >>$NETWORK_FILE
   i=$(($i + 1))
done
echo "</dhcp>" >>$NETWORK_FILE
echo "</ip>" >>$NETWORK_FILE
echo "</network>" >>$NETWORK_FILE


/usr/bin/virsh net-destroy  $NETWORK_NAME
/usr/bin/virsh net-undefine $NETWORK_NAME
/usr/bin/virsh net-define $NETWORK_FILE # network creation command
/usr/bin/virsh net-start $NETWORK_NAME
/usr/bin/virsh net-autostart $NETWORK_NAME

#Downloading VM cloud image

wget  -N $image_url


#Creating VM now for all machines

i=0
while [ $i -lt $no_of_vms ]
do

   echo "Building $i . VM named ${HOSTS_array[i]}"
   mkdir -p /var/lib/libvirt/images/${HOSTS_array[i]}/base
   cp -p $download_image_name /var/lib/libvirt/images/${HOSTS_array[i]}/base/${HOSTS_array[i]}.qcow2
   echo "Creating disk ..................................."
   /usr/bin/qemu-img create -f qcow2 -F qcow2 -o backing_file=/var/lib/libvirt/images/${HOSTS_array[i]}/base/${HOSTS_array[i]}.qcow2 /var/lib/libvirt/images/${HOSTS_array[i]}/${HOSTS_array[i]}.qcow2

   /usr/bin/qemu-img resize /var/lib/libvirt/images/${HOSTS_array[i]}/${HOSTS_array[i]}.qcow2 ${DISK_array[i]}
    
   cat<<EOF  |  tee  /var/lib/libvirt/images/${HOSTS_array[i]}/meta-data 
local-hostname: ${HOSTS_array[i]}
EOF

   cat<<EOF | tee  /var/lib/libvirt/images/${HOSTS_array[i]}/user-data 
#cloud-config
users:
  - name: $VM_USER
    ssh-authorized-keys:
      - $PUB_KEY
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
runcmd:
  - echo "AllowUsers $VM_USER" >> /etc/ssh/sshd_config
  - restart ssh

EOF


   /usr/bin/genisoimage  -output /var/lib/libvirt/images/${HOSTS_array[i]}/${HOSTS_array[i]}-cidata.iso -volid cidata -joliet -rock  /var/lib/libvirt/images/${HOSTS_array[i]}/user-data /var/lib/libvirt/images/${HOSTS_array[i]}/meta-data
   echo "/usr/bin/genisoimage  -output /var/lib/libvirt/images/${HOSTS_array[i]}/${HOSTS_array[i]}-cidata.iso -volid cidata -joliet -rock  /var/lib/libvirt/images/${HOSTS_array[i]}/user-data /var/lib/libvirt/images/${HOSTS_array[i]}/meta-data"

   echo "Creating VMs please wait..................................."
   
    /usr/bin/virt-install --connect qemu:///system --virt-type kvm  --hvm --name ${HOSTS_array[i]} --ram ${RAM_array[i]} --vcpus=${CPU_array[i]} \
   --os-type linux --os-variant $VERSION --disk path=/var/lib/libvirt/images/${HOSTS_array[i]}/${HOSTS_array[i]}.qcow2,format=qcow2 \
   --disk /var/lib/libvirt/images/${HOSTS_array[i]}/${HOSTS_array[i]}-cidata.iso,device=cdrom --import \
   --network=$NETWORK_NAME,model=virtio,mac=${MACID_array[i]}  \
   --filesystem /home/$HOST_USER/KVM_SHARE,/home/$VM_USER  \
   --noautoconsole 

   #sleep 90
   sudo virsh list

   
   i=$(($i + 1))
done
