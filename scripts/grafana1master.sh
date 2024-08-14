#!
clear
# echo "please input the namespace where everything will be installed"
# read namespace
# echo
kubectl create -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/master/bundle.yaml
sleep 5
kubectl get deploy
echo
cd operator_k8s
echo
kubectl apply -f prom_rbac.yaml
sleep 5
kubectl apply -f prometheus1.yaml
sleep 5
echo
echo
kubectl get prometheus
echo 
echo
kubectl get pod
echo
echo
kubectl apply -f prom_svc.yaml
sleep 5
echo
echo
kubectl get service
echo 
echo
kubectl port-forward svc/prometheus 9090
sleep 5
echo 
echo "Navigate to http://localhost:9090 to access the Prometheus interface"
echo "serviceMonitor, k8s secret to grafana cloud, and deduplication to be added. please allow some time for serviceMonitor to catch up."
echo
echo
kubectl apply -f prometheus_servicemonitor.yaml
sleep 5
echo
echo "forward a port to your Prometheus server and check its configuration for verification"
kubectl --namespace default get service
echo
echo
kubectl --namespace default port-forward svc/<prometheus service name> 9090
echo
echo
echo "in the Prometheus interface, Navigate to Status, and then Targets. You should see the two Prometheus replicas as scrape targets. (give some time if no update). Navigate to Graph, in the Expression box, type prometheus_http_requests_total, and press ENTER. You should see a list of scraped metrics and their values. These are HTTP request counts for various Prometheus server endpoints. Now you have configured Prometheus to scrape itself and store metrics locally."
echo
# echo "input your grafana username"
# read grafUser
# echo
# echo "input your grafana token" 
# read grafToken
# echo
echo
# echo "Note: If you deployed your monitoring stack in a namespace other than default, append the -n flag with the appropriate namespace to the below command."

kubectl create secret generic kubepromsecret \
	--from-literal=username=<your_grafana_cloud_prometheus_username>\
      	--from-literal=password='<your_grafana_cloud_access_policy_token>'
echo 
echo 
kubectl apply -f prometheus2.yaml
sleep 5
echo
echo
kubectl port-forward svc/prometheus 9090
sleep 5
echo 
echo
echo "From the Cloud Portal, click Log In next to the Grafana card to log in to Grafana.

Click Explore in the left-side menu.

In the PromQL query box, enter the same metric you tested earlier, prometheus_http_requests_total, and press SHIFT + ENTER.

You should see a graph of time-series data corresponding to different labels of the prometheus_http_requests_total metric. Grafana queries this data from the Grafana Cloud Metrics data store, not your local Cluster.

Navigate to Kubernetes Monitoring, and click Configuration on the main menu.

Click the Metrics status tab to view the data status. Your data begins populating in the view as the system components begin scraping and sending data to Grafana Cloud."
echo
echo


echo




