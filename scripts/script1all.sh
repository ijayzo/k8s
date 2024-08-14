#!
clear
sudo dnf install kernel-devel-$(uname -r) -y
sleep 45
sudo modprobe br_netfilter
sudo modprobe ip_vs
sudo modprobe ip_vs_rr
sudo modprobe ip_vs_wrr
sudo modprobe ip_vs_sh
sudo modprobe overlay
echo
sudo chmod o+w /etc/modules-load.d/
sudo cat > /etc/modules-load.d/kubernetes.conf << EOF
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
overlay
EOF
echo
sudo chmod o-w /etc/modules-load.d/
echo 
sudo chmod o+w /etc/sysctl.d 
sudo cat > /etc/sysctl.d/kubernetes.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
echo
sudo chmod o-w /etc/sysctl.d
echo
sudo sysctl --system
sudo swapoff -a
sudo sed -e '/swap/s/^/#/g' -i /etc/fstab
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sleep 5
sudo dnf makecache
sleep 10
sudo dnf -y install containerd.io
sleep 45
echo
sudo sh -c "containerd config default > /etc/containerd/config.toml" ; cat /etc/containerd/config.toml
sed 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl enable --now containerd.service
sleep 3
sudo systemctl reboot
