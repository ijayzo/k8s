#!
clear
sudo dnf install kernel-devel-$(uname -r)
sleep 5
sudo modprobe br_netfilter
sudo modprobe ip_vs
sudo modprobe ip_vs_rr
sudo modprobe ip_vs_wrr
sudo modprobe ip_vs_sh
sudo modprobe overlay
echo
cat > /etc/modules-load.d/kubernetes.conf << EOF
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
overlay
EOF
echo 
cat > /etc/sysctl.d/kubernetes.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
echo
sysctl --system
sudo swapoff -a
sed -e '/swap/s/^/#/g' -i /etc/fstab
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sleep 10
sudo dnf makecache
sleep 5
sudo dnf -y install containerd.io
echo
sudo sh -c "containerd config default > /etc/containerd/config.toml" ; cat /etc/containerd/config.toml
sed 's/SystemdCgroup = false/SystemdCgroup = true/'
sudo systemctl enable --now containerd.service
sleep 3
sudo systemctl reboot
sleep 60
sudo systemctl status containerd.service
sudo firewall-cmd --zone=public --permanent --add-port=6443/tcp
sudo firewall-cmd --zone=public --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --zone=public --permanent --add-port=10250/tcp
sudo firewall-cmd --zone=public --permanent --add-port=10251/tcp
sudo firewall-cmd --zone=public --permanent --add-port=10252/tcp
sudo firewall-cmd --zone=public --permanent --add-port=10255/tcp
sudo firewall-cmd --zone=public --permanent --add-port=5473/tcp
sudo firewall-cmd --reload
sleep 5 
sudo cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
dnf makecache; dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sleep 10
systemctl enable --now kubelet.service






