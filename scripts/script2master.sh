#!
clear
sudo kubeadm config images pull
sleep 10
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
sleep 15
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml
sleep 10
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml
sleep 5 
sed -i 's/cidr: 192\.168\.0\.0\/16/cidr: 10.244.0.0\/16/g' custom-resources.yaml
echo
kubectl create -f custom-resources.yaml
echo
sleep 2
echo "please use the join command below"
sudo kubeadm token create --print-join-command
sleep 5
echo
echo "please use the join command above"

