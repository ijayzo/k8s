# k8s
k8s = kubernetes. 3 nginx deployments with grafana/promethes, dashboards, rolling restart

please use https://github.com/ijayzo/terraformInstances as a guide to setting up and SSH'ing into instances using terraform (only difference is you need 3 instances here, and you will change the name on the aws console of the instances for ease of use) or you can manually create instances on the AWS console. Prefereable K8s instances should be bigger than T2/3. 

---
notes
need to install k8s, network, container runtime as docker 

https://infotechys.com/install-a-kubernetes-cluster-on-rhel-9/


---
steps 

1) SSH into all 3 isntances or connect on the AWS console with the "EC2 Instance Connect". 
2) On all instances:
	- for docker as container runtime
		
	- for non docker =
		+ Set SELinux in permissive mode (effectively disabling it). root access or sudo access. This is required to allow containers to access the host filesystem; for example, some cluster network plugins require that. You have to do this until SELinux support is improved in the kubelet.
You can leave SELinux enabled if you know how to configure it but it may require settings that are not supported by kubeadm.
			sudo setenforce 0
			sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config 
		+ Add K8s dnf repository
			# This overwrites any existing configuration in /etc/yum.repos.d/kubernetes.repo
```
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
```
		+ install kubelet, kubeadm, and kubectl
			sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
		+ enable the kubelet service before running kubeadm
			sudo systemctl enable --now kubelet
3) on the master node, as root or using sudo:
	sudo kubeadm init
		upon successful initialization, 3 codes will be provided -> denoted with 1, 2, and 3 stars (*) -> (*) to set up the machine user as master. (***) to set up root of machine as the master. (***) to join the cluster created by the master (master needs to join as well)
			(*) there will be a section stating "to start using your cluster, you need to run the following as a regular user" with the following commands:
				mkdir -p $HOME/.kube
				sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
				sudo chown $(id -u):$(id -g) $HOME/.kube/config
			(**) "alternatively, if you are the root user, you can run":
				export KUBECONFIG=/etc/kubernetes/admin.conf
			(***) "Then you can join any number of worker nodes by running the folliwing on each as root:"
				(given, just an example)
				kubeadm join <ip>:<cidr block> --token <token> \ discovery-token-ca-cert-hash sha256:<token>				 
all nodes, including master: 
				
 
