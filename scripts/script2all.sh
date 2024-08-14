#!
clear
# sudo systemctl status containerd.service
sudo dnf install firewalld -y
sleep 10
sudo systemctl enable --now firewalld 
sleep 3
echo
sudo firewall-cmd --zone=public --permanent --add-port=6443/tcp
sleep 2
echo
sudo firewall-cmd --zone=public --permanent --add-port=2379-2380/tcp
sleep 2
echo
sudo firewall-cmd --zone=public --permanent --add-port=10250/tcp
sleep 2
echo
sudo firewall-cmd --zone=public --permanent --add-port=10251/tcp
sleep 2
echo
sudo firewall-cmd --zone=public --permanent --add-port=10252/tcp
sleep 2
echo
sudo firewall-cmd --zone=public --permanent --add-port=10255/tcp
sleep 2
echo
sudo firewall-cmd --zone=public --permanent --add-port=5473/tcp
sleep 2
echo
sudo firewall-cmd --reload
sleep 2
echo
echo
sudo cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
sudo dnf makecache; sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sleep 10
sudo systemctl enable --now kubelet.service






