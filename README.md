# Creating Kubernetes Cluster Using Ansible and KVM

> This method uses Kubernetes by Hard Way

<!-- #region -->
## Prerequisite

1. Linux Servers with Ubuntu 18.04 installed
2. SSH connection ready on all server with private key access
3. Install Python3 if not installed on Control Server, from where we are going to control the complete setup (it can be our PC)
4. Install Ansible on Control Server, from where we are going to control the complete setup (it can be our PC)
5. Download the executables and add those to the archive , Your archives should look like this:
6. Install KVM in host machine


```
➜  k8s git:(master) ✗ tar -tzvf master.tar.gz
-rwxr-xr-x gaurav/gaurav 120627200 2020-06-11 09:31 kube-apiserver
-rwxr-xr-x gaurav/gaurav 110030848 2020-06-11 09:31 kube-controller-manager
-rwxr-xr-x gaurav/gaurav  44023808 2020-03-26 00:50 kubectl
-rwxr-xr-x gaurav/gaurav  42938368 2020-06-11 09:31 kube-scheduler
-rwxr-xr-x gaurav/gaurav  23827424 2020-05-22 01:24 etcd
-rwxr-xr-x gaurav/gaurav  17612384 2020-05-22 01:24 etcdctl
➜  k8s git:(master) ✗

➜  k8s git:(master) ✗ tar -tvzf slave.tar.gz
-rwxr-xr-x gaurav/gaurav 32751272 2020-05-15 05:59 containerd
-rwxr-xr-x gaurav/gaurav  6012928 2020-05-15 05:59 containerd-shim
-rwxr-xr-x gaurav/gaurav 18194536 2020-05-15 05:59 ctr
-rwxr-xr-x gaurav/gaurav 61113382 2020-05-15 05:59 docker
-rwxr-xr-x gaurav/gaurav 68874208 2020-05-15 05:59 dockerd
-rwxr-xr-x gaurav/gaurav   708616 2020-05-15 05:59 docker-init
-rwxr-xr-x gaurav/gaurav  2928514 2020-05-15 05:59 docker-proxy
-rwxr-xr-x gaurav/gaurav 44023808 2020-06-11 09:32 kubectl
-rwxr-xr-x gaurav/gaurav 113255096 2020-06-11 09:31 kubelet
-rwxr-xr-x gaurav/gaurav  38375424 2020-06-11 09:31 kube-proxy
-rwxr-xr-x gaurav/gaurav   9600696 2020-05-15 05:59 runc
➜  k8s git:(master) ✗

➜  k8s git:(master) ✗ tar -tvzf cni.tar.gz
-rwxr-xr-x gaurav/gaurav 4159518 2020-05-14 01:20 bandwidth
-rwxr-xr-x gaurav/gaurav 4671647 2020-05-14 01:20 bridge
-rwxr-xr-x gaurav/gaurav 12124326 2020-05-14 01:20 dhcp
-rwxr-xr-x gaurav/gaurav  5945760 2020-05-14 01:20 firewall
-rwxr-xr-x gaurav/gaurav  3069556 2020-05-14 01:20 flannel
-rwxr-xr-x gaurav/gaurav  4174394 2020-05-14 01:20 host-device
-rwxr-xr-x gaurav/gaurav  3614480 2020-05-14 01:20 host-local
-rwxr-xr-x gaurav/gaurav  4314598 2020-05-14 01:20 ipvlan
-rwxr-xr-x gaurav/gaurav  3209463 2020-05-14 01:20 loopback
-rwxr-xr-x gaurav/gaurav  4389622 2020-05-14 01:20 macvlan
-rwxr-xr-x gaurav/gaurav  3939867 2020-05-14 01:20 portmap
-rwxr-xr-x gaurav/gaurav  4590277 2020-05-14 01:20 ptp
-rwxr-xr-x gaurav/gaurav  3392826 2020-05-14 01:20 sbr
-rwxr-xr-x gaurav/gaurav  2885430 2020-05-14 01:20 static
-rwxr-xr-x gaurav/gaurav  3356587 2020-05-14 01:20 tuning
-rwxr-xr-x gaurav/gaurav  4314446 2020-05-14 01:20 vlan
➜  k8s git:(master) ✗

```

6. Rename `INVENTORY.ini_demo` to `INVENTORY.ini` 

**Your directory structure should look like :**

```
➜  k8s git:(master) ✗ ll ~/DEVELOPMENT/coding/k8s
total 239M
-rw-r--r-- 1 gaurav gaurav  122 Jun 11 09:01 ansible.cfg
-rw-r--r-- 1 gaurav gaurav  128 Jun 12 11:16 get_master_ips.j2
-rw-r--r-- 1 gaurav gaurav  130 Jun 12 12:09 get_master_hostnames.j2
-rw-r--r-- 1 gaurav gaurav  129 Jun 12 21:18 get_slave_hostnames.j2
-rw-r--r-- 1 gaurav gaurav  127 Jun 12 21:38 get_slave_ips.j2
-rw-r--r-- 1 gaurav gaurav  94M Jun 13 01:24 master.tar.gz
-rw-r--r-- 1 gaurav gaurav  36M Jun 13 03:25 cni.tar.gz
drwxr-xr-x 3 gaurav gaurav 4.0K Jun 13 08:21 remote_manager
drwxr-xr-x 3 gaurav gaurav 4.0K Jun 13 08:45 master
drwxr-xr-x 2 gaurav gaurav 4.0K Jun 13 09:18 slave
-rw-r--r-- 1 gaurav gaurav 2.4K Jun 13 09:42 1_pre-configure_networking.yml
-rw-r--r-- 1 gaurav gaurav 110M Jun 13 11:50 slave.tar.gz
-rw-r--r-- 1 gaurav gaurav 1.8K Jun 13 22:58 zerotier_using_curl.md
-rw-r--r-- 1 gaurav gaurav 4.3K Jun 13 23:35 3_SetupMaster.yml
-rw-r--r-- 1 gaurav gaurav 3.5K Jun 14 00:32 4_SetupSlave.yml
-rw-r--r-- 1 gaurav gaurav 1.8K Jun 17 04:29 2_remote-manager-configure.yml
-rw-r--r-- 1 gaurav gaurav 1.2K Jun 17 04:30 INVENTORY.ini
-rw-r--r-- 1 gaurav gaurav 1.2K Jun 23 09:51 INVENTORY.ini_demo
-rw-r--r-- 1 gaurav gaurav 3.7K Jun 23 10:11 README.md
➜  k8s git:(master) ✗


```
<!-- #endregion -->

<!-- #region -->
## Getting Started 

### Creating Configuration Files

1. **ansible.cfg**:   
    -add few ansible configuration here
2. **INVENTORY.ini**:    
    - add all servers here (master1,master2,slave1,slave2)


### For provisioning go to provision directory and run from 

1. Run `ansible-playbook 1_provisioning_vms.yml`
2. Run `ansible-playbook 2_NFS_provision_in_VMs.yml`
  
### Making it Run (from 10 to 50 in increasing order)

3. Run `ansible-playbook 10_pre-configure_networking.yml`

4. Run `ansible-playbook 20_remote-master-configure.yml`

5. Run `ansible-playbook 21_remote-slave-configure.yml`

6. Run `ansible-playbook 30_SetupMaster.yml`

7. Run `ansible-playbook 40_SetupSlave.yml`
   
8. Run `ansible-playbook 50_Create_Routes.yml`

9.  Add the context and config file in remote control manager

```
cd ~/gen_keys


{
  KUBERNETES_PUBLIC_ADDRESS=192.168.122.3

  kubectl config set-cluster Kubernetes_by_Ansible \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem

  kubectl config set-context Kubernetes_by_Ansible \
    --cluster=Kubernetes_by_Ansible \
    --user=admin

  kubectl config use-context Kubernetes_by_Ansible
}


```

> `KUBERNETES_PUBLIC_ADDRESS` is the ip of the master for single master cluster

7. Add DNS

`kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml`

<!-- #endregion -->
