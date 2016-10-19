#!/bin/bash
# Filename: kubernetes_install_master.sh
# Author: shuhui
# Version: v1.0

# Devfine Var
IP_RANGE="172.16.4.0/24"

# Install Kubernetes package on master node
yum -y install kubernetes etcd flannel

# Generate server key
openssl genrsa -out /etc/kubernetes/service.key 2048

# Config
sed -i "s:KUBE_CONTROLLER_MANAGER_ARGS=.*:KUBE_CONTROLLER_MANAGER_ARGS=\"--service_account_private_key_file=/etc/kubernetes/service.key\":" /etc/kubernetes/controller-manager

sed -i 's:KUBE_API_ADDRESS=.*:KUBE_API_ADDRESS="--address=0.0.0.0":' /etc/kubernetes/apiserver
sed -i "s/KUBE_ETCD_SERVERS=.*/KUBE_ETCD_SERVERS=\"--etcd_servers=http:\/\/${HOSTNAME}:2379\"/" /etc/kubernetes/apiserver
sed -i "s:KUBE_SERVICE_ADDRESSES=.*:KUBE_SERVICE_ADDRESSES=\"--service-cluster-ip-range=${IP_RANGE}\":" /etc/kubernetes/apiserver
echo -en "\nKUBE_API_ARGS=\"--service_account_key_file=/etc/kubernetes/service.key\"" >> /etc/kubernetes/apiserver

sed -i '7s/#//' /etc/etcd/etcd.conf
sed -i "s/ETCD_LISTEN_CLIENT_URLS=.*/ETCD_LISTEN_CLIENT_URLS=\"http:\/\/localhost:2379,http:\/\/${HOSTNAME}:2379\"/" /etc/etcd/etcd.conf

sed -i "s/KUBE_MASTER=.*/KUBE_MASTER=\"--master=http:\/\/${HOSTNAME}:8080\"/" /etc/kubernetes/config


# 启动
systemctl start etcd kube-apiserver kube-controller-manager kube-scheduler
systemctl enable etcd kube-apiserver kube-controller-manager kube-scheduler

cat > flannel-config.json <<EOF
{
  "Network":"172.16.0.0/16",
  "SubnetLen":24,
  "Backend":{
    "Type":"vxlan",
    "VNI":1
  }
}
EOF

sed -i "s/FLANNEL_ETCD=.*/FLANNEL_ETCD=\"http:\/\/${HOSTNAME}:2379\"/" /etc/sysconfig/flanneld
sed -i "s/FLANNEL_ETCD_KEY=.*/FLANNEL_ETCD_KEY=\"\/atomic.io\/network\"/" /etc/sysconfig/flanneld
etcdctl set atomic.io/network/config < flannel-config.json
systemctl start flanneld
systemctl enable flanneld
echo "flannel running status"
kubectl cluster-info
