#k8s

k8s = kubernetes. 3 nginx deployments with grafana/promethes, dashboards, rolling restart

please use https://github.com/ijayzo/terraformInstances as a guide to setting up and SSH'ing into instances using terraform (only difference is you need 3 instances here, and you will change the name on the aws console of the instances for ease of use) or you can manually create instances on the AWS console. Prefereable K8s instances should be bigger than T2/3.

---
notes

# need to install k8s, network, container runtime as docker

- https://infotechys.com/install-a-kubernetes-cluster-on-rhel-9/

	Steps 1-11 = installing k8s, making cluster, and connecting nodes to cluster 

	Also, scripts can be found in the repo to run all the commands from the below steps. script1all.sh is step 1-7. script2master.sh runs steps 8 and 9 on the master node; the output will be the join command to be used on the worker nodes. script3master will deploy 3 replicas of nginx exposed on port 80; but you need to create/copy the yaml deployment manifests.

	The scripts need execute permission. please use: chmod u+x <absolute path of script file>.sh
	
# need to install prometheus and grafana

- https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/config-other-methods/prometheus/prometheus-operator/

	Starts at step 12

# need to setup a dashboard

- https://grafana.com/docs/grafana/latest/dashboards/

# need to do a rolling restart 

- https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/kubectl_rollout_restart/ 

# Add additional endpoints to scrape, such as the Kubernetes API or kubelet metrics from the Kubernetes nodes. To see a fully configured Prometheus Kubernetes stack in action, refer to kube-prometheus.

- https://github.com/prometheus-operator/kube-prometheus

---
to fix later

change namespace away from default 



---
step 1

- on all nodes, add kernel modules
	
	# install appropriate kernel headers on your system
	+ sudo dnf install kernel-devel-$(uname -r)

	# load necessary kernel modules req'ed by k8s. help w/ fuctionality and facilitate comm's w/i the k8s cluster (servers become prepared for k8s installation and can effectively manage networking and load balancing tasks w/i the cluster)
	+ sudo modprobe br_netfilter
	+ sudo modprobe ip_vs
	+ sudo modprobe ip_vs_rr
	+ sudo modprobe ip_vs_wrr
	+ sudo modprobe ip_vs_sh
	+ sudo modprobe overlay
	 
	# create config file (as the root)

```
cat > /etc/modules-load.d/kubernetes.conf << EOF
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
overlay
EOF
```

---

step 2

- on all nodes, configure systctl

	# set specific systctl settings that k8s relies on (can update system's kernel parameters. here, we enable ipv4 packet forwarding, iptable to process bridged ipv4 & ipv6 traffic). "By setting these sysctl parameters, you ensure that your system is properly configured to support Kubernetes networking requirements and forwarding of network traffic within the cluster. These settings are essential for the smooth operation of Kubernetes networking components."


```

cat > /etc/sysctl.d/kubernetes.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

```

	# apply the changes 
	+ sysctl --system

---

step 3

- on all nodes, disable swap 

	# disable swap on your server/worker node. then, turn off all swap devices (comment out the line that begins with "swap")
	+ sudo swapoff -a
	+ sed -e '/swap/s/^/#/g' -i /etc/fstab

---

step 4

- on all nodes, install containerd

	# before configuring containerd, we need to add docker repo to our system (will be usuing Docker CE) as it offers essential components for container management. then, must udpate the package cache. then,  install containerd.

	+ sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	+ sudo dnf makecache
	+ sudo dnf -y install containerd.io

---

step 5

- on all nodes, configure containerd
	
	#  "ensure optimal performance and compatibility with your environment. The configuration file for Containerd is located at /etc/containerd/config.toml". only small adjustments to enable Systemd Cgroup support, essential for proper container management. 
	
	# see the file with cat command. the next command then builds out the containerd cofig file and outputs the file again.
	+ cat /etc/containerd/config.toml
	+ sudo sh -c "containerd config default > /etc/containerd/config.toml" ; cat /etc/containerd/config.toml

	# change SystemdCgroup variable in /etc/containerd/config.toml file to true. provides enhanced compatibility for managing containers w/i systemd env.
	+ sudo vim /etc/containerd/config.toml
	+ SystemdCgroup = true

	# ensure containerd.service starts up and is enabled. must reboot. can confirm with status command.
	+ sudo systemctl enable --now containerd.service
	+ sudo systemctl reboot
	+ sudo systemctl status containerd.service

---

step 6 

- on all nodes, set firewall rules 
	
	# allow specific ports used by k8s components through the firewall. 6443 = Kubernetes API server. 2379-2380 = etcd server client API. 10250 = Kubelet API.10251	= kube-scheduler. 10252	= kube-controller-manager. 10255 = Read-only Kubelet API. 5473 = ClusterControlPlaneConfig API. 
	+ sudo firewall-cmd --zone=public --permanent --add-port=6443/tcp
	+ sudo firewall-cmd --zone=public --permanent --add-port=2379-2380/tcp
	+ sudo firewall-cmd --zone=public --permanent --add-port=10250/tcp
	+ sudo firewall-cmd --zone=public --permanent --add-port=10251/tcp
	+ sudo firewall-cmd --zone=public --permanent --add-port=10252/tcp
	+ sudo firewall-cmd --zone=public --permanent --add-port=10255/tcp
	+ sudo firewall-cmd --zone=public --permanent --add-port=5473/tcp

	# relaod firewall to apply changes 
	+ sudo firewall-cmd --reload

---

step 7

- on all nodes, install k8s components (kubelet, kuubeadm, kubectl) and add the k8s repo to your package manager

	# add k8s repo to your package manager. 

```
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
```

	# install k8s packages 
	+ dnf makecache; dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

	# start and enable kubelet service 
	+ systemctl enable --now kubelet.service

	# don't worry about any kubelet errors at this point. still need the join command.

---

step 8

- on the master node, initialize the k8s control plane 
	
	# first pull necessary container images for the default container registry to store them locally; ensures all req'edimagesare available locally and can be used w/o relying on external registry during cluster setup. then initialize
	+ sudo kubeadm config images pull
	+ sudo kubeadm init --pod-network-cidr=10.244.0.0/16

	# setup kubeconfig file 
	+ mkdir -p $HOME/.kube
	+ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	+ sudo chown $(id -u):$(id -g) $HOME/.kube/config

	# deploy pod network 
	+ kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

	# download Calico resources manifest as a YAML. use one command or the other 
	+ curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml
	+ wget https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml
	
	# adjust the cidr setting in the custom resources file 
	+ sed -i 's/cidr: 192\.168\.0\.0\/16/cidr: 10.244.0.0\/16/g' custom-resources.yaml
	
	# create the Calico custom resources 
	+ kubectl create -f custom-resources.yaml

---

step 9

- join the worker nodes to the cluster
	
	# on the master node, generate the join command along w/ a token. the worker nodes will use the token and the master node's ip address to connect to the cluster. 
	+ sudo kubeadm token create --print-join-command	

	# copy the join command outputted by the previous command that will include the token and the master node's ip. will look something like: 
	+ sudo kubeadm join <MASTER_IP>:<MASTER_PORT> --token <TOKEN> --discovery-token-ca-cert-hash <DISCOVERY_TOKEN_CA_CERT_HASH>

	# paste the join command onto every worker node that will be joining the cluster.

	# on the master node, verify the worker nodes joined
	+ kubectl get nodes

---

step 10

- on the master node, nginx test deployment 

	# use the following yaml manifest to deploy applications, such as nginx (as a test deployment). save as nginx-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

	# apply the deployment file, name changes, using nginx-deployment.yaml
	+ kubectl apply -f nginx-deployment.yaml

	# check the status of the deployment 
	+ kubectl get deployments

	# verify that the nginx pods are running 
	+ kubectl get pods

---

step 11

- on the master node, expose the nginx to the external network using a k8s service

	# save the yaml file (using nginx-service.yaml) 

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
```
	
	# apply the service (LoadBalancer, which exposes the nginx deployment to the external network).
	+ kubectl apply -f nginx-service.yaml

	# attain the external ip address of the nginx service 
	+ kubectl get service nginx-service
	+ (use the given ip in a web browser to see the default nginx welcome page)

	# more methods to expose the service in the link given at beginning of this readme

---

step 12
 
- ensure that the cluster has RBAC enabled

	# run the following command
	+ kubectl api-versions
	
	# check if the API version starts with rbac.authorization,
	+ .rbac.authorization.k8s.io/v1
	
	# if not, please enable rbac
	+ https://komodor.com/learn/kubernetes-rbac/#:~:text=RBAC%20is%20enabled%20by%20default,the%20command%20kubectl%20api%2Dversions.

---

step 13

- create a grafana cloud account 

	# https://grafana.com/auth/sign-up

---

step 14

- create a Grafana Cloud access policy token with the metrics:write scope. To create a Grafana Cloud access policy, refer to Create a Grafana Cloud Access Policy. 


---

step 15

- Install Prometheus Operator into the Kubernetes Cluster.

	# Install the Operator using the bundle.yaml file in the Prometheus Operator GitHub repository. bundle.yaml installs CRDs for Prometheus objects as well as a Prometheus Operator controller and service.
	+ kubectl create -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/master/bundle.yaml

	# Verify that the Prometheus Operator installation succeeded
	+ kubectl get deploy

---

step 16

- Configure RBAC permissions for Prometheus.

	# Create a directory to store Kubernetes manifests, and cd into it
	+ mkdir operator_k8s
	+ cd operator_k8s

	# Create a manifest file called prom_rbac.yaml. This creates a ServiceAccount called prometheus and binds it to the prometheus ClusterRole. The manifest grants the ClusterRole get, list, and watch Kubernetes API privileges.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/metrics
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources:
  - configmaps
  verbs: ["get"]
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: default
```

	# create the objects 
	+ kubectl apply -f

---
step 15

- deploy Prometheus into the Cluster using the Operator.

	# create a file called prometheus.yaml. 2-replica HA Prometheus deployment (plus the operator = 3 nodes).

```yaml
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: prometheus
  labels:
    app: prometheus
spec:
  image: quay.io/prometheus/prometheus:v2.22.1
  nodeSelector:
    kubernetes.io/os: linux
  replicas: 2
  resources:
    requests:
      memory: 400Mi
  securityContext:
    fsGroup: 2000
    runAsNonRoot: true
    runAsUser: 1000
  serviceAccountName: prometheus
  version: v2.22.1
  serviceMonitorSelector: {}
```

	# Deploy the manifest into your Cluster 
	+ kubectl apply -f

	# verify
	+ kubectl get prometheus
	
	# check underlying pods
	+ kubectl get pod

---

step 16

- expose the Prometheus server as a service.

	# create manifest file called prom_svc.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  labels:
    app: prometheus
spec:
  ports:
  - name: web
    port: 9090
    targetPort: web
  selector:
    app.kubernetes.io/name: prometheus
  sessionAffinity: ClientIP
```

	# Deploy the manifest into your Cluster
	+ kubectl apply -f
	
	# verify
	+ kubectl get service

	# "To access the Prometheus server, forward a local port to the Prometheus service running inside of the Kubernetes Cluster"
	+ kubectl port-forward svc/prometheus 9090

	# Navigate to http://localhost:9090 to access the Prometheus interface

	# Click Status, then Targets to see any configured scrape targets. Should be empty

---

step 17

- create a ServiceMonitor.

	# create a file called prometheus_servicemonitor.yaml

	# create a file called prometheus_servicemonitor.yaml

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: prometheus-self
  labels:
    app: prometheus
spec:
  endpoints:
  - interval: 30s
    port: web
  selector:
    matchLabels:
      app: prometheus
```

	# Deploy the manifest into your Cluster
	+ kubectl apply -f prometheus_servicemonitor.yaml

--- 

step 18 

- Forward a port to your Prometheus server and check its configuration for verification.
	
	# Find the name of the Prometheus service
	+ kubectl --namespace default get service

	# In the Prometheus interface:
	+ Go to Status, then Targets. Should see 2 Prometheus replicas as scrape targets.
	+ Go to Graph, in the Expression box type prometheus_http_requests_total

--- 

step 19

- Create a Kubernetes Secret to store Grafana Cloud credentials

	# you can create the Kubernetes Secret using a manifest file or directly using kubectl. Note: If you deployed your monitoring stack in a namespace other than default, append the -n flag with the appropriate namespace to the above command.
	+ kubectl create secret generic kubepromsecret \
  --from-literal=username=<your_grafana_cloud_prometheus_username>\
  --from-literal=password='<your_grafana_cloud_access_policy_token>'

---

step 20

- Configure Prometheus remote_write and metrics deduplication

	# add the following to the end of your resource definition in the previously created prometheus.yaml file. Configure remote_write to send Cluster metrics to Grafana Cloud and to deduplicate metrics. The remote_write Prometheus feature allows you to send metrics to remote endpoints for long-term storage and aggregation. Grafana Cloud’s deduplication feature allows you to deduplicate metrics sent from high-availability Prometheus pairs, which reduces your active series usage

```yaml
. . .
  remoteWrite:
  - url: "<Your Metrics instance remote_write endpoint>"
    basicAuth:
      username:
        name: kubepromsecret
        key: username
      password:
        name: kubepromsecret
        key: password
  replicaExternalLabelName: "__replica__"
  externalLabels:
    cluster: "<choose_a_prom_cluster_name>"
```
	
	# Deploy the manifest into your Cluster
	+ kubectl apply -f prometheus.yaml

	# may take a couple minutes, but navigate to http://localhost:9090 in your browser, and then Status and Configuration. Verify that the remote_write and external_labels blocks you appended earlier have propagated to your running Prometheus instances.

---

step 21

	# Access your Prometheus metrics in Grafana Cloud
	+ From the Cloud Portal, click Log In next to the Grafana card to log in to Grafana. Click Explore in the left-side menu. In the PromQL query box, enter the same metric you tested earlier, prometheus_http_requests_total, and press SHIFT + ENTER. You should see a graph of time-series data corresponding to different labels of the prometheus_http_requests_total metric. Grafana queries this data from the Grafana Cloud Metrics data store, not your local Cluster. Navigate to Kubernetes Monitoring, and click Configuration on the main menu. Click the Metrics status tab to view the data status. Your data begins populating in the view as the system components begin scraping and sending data to Grafana Cloud.

---

step 22 

- create a dashboard - rows of single/grouped panels (visual representations of data/queries) organized to show similar data. we will be using variables to create the dashboards. variables allow for one dashboard to be used by any of your clusters/instances just by changing the ip, instead of creating a new dashboard for each server. also, makes sure that your users can't change the panel settings.

	# ensure you have the right permissions
	+ https://grafana.com/docs/grafana/latest/administration/roles-and-permissions/

	# within your grafana, make a new dashboard (or editing an old dashboard), and go to settings at the top. this is where you will find the variables section.
	+ 
	
	#
	+ 


