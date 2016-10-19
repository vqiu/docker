#!/bin/bash
# Filename: kubernetes_install_node.sh
# Author: shuhui
# Version: v1.0

MASTER="server.vqiu.cn"          # Master Server Address
NODE_NAME="$1"                   # Local node name

if [[ $# -ne 1 ]]; then
	echo "Useage: $0 nodename"
	exit 1
fi

ping -c 2 ${NODE_NAME} >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
	echo "Please enter a valid nodeName."
	exit 1
fi

# Install kubernetes package on node
yum -y install kubernetes flannel

sed -i "s/KUBE_MASTER=.*/KUBE_MASTER=\"--master=http:\/\/${MASTER}:8080\"/" /etc/kubernetes/config

sed -i "s/KUBELET_ADDRESS=.*/KUBELET_ADDRESS=\"--address=0.0.0.0\"/" /etc/kubernetes/kubelet

sed -i "s/KUBELET_HOSTNAME=.*/KUBELET_HOSTNAME=\"--hostname_override=${NODE_NAME}\"/" /etc/kubernetes/kubelet

sed -i "s/KUBELET_API_SERVER=.*/KUBELET_API_SERVER=\"--api_servers=http:\/\/${MASTER}:8080\"/" /etc/kubernetes/kubelet

sed -i "s/FLANNEL_ETCD=.*/FLANNEL_ETCD=\"http:\/\/${MASTER}:2379\"/" /etc/sysconfig/flanneld

# Down docker0 interface
nmcli con down docker0

systemctl start flanneld kube-proxy kubelet
systemctl enable flanneld kube-proxy kubelet 
systemctl restart docker

echo -en "\nRun follow command on master server\nkubectl get nodes\n"
