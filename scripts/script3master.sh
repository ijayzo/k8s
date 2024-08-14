#!
clear
sudo systemctl stop kubelet
sleep 2
sudo systemctl start kubelet
sleep 2
kubectl apply -f nginx-deployment.yaml
sleep 5
kubectl get deployments
sleep 3
kubectl get pods
sleep 3
kubectl apply -f nginx-service.yaml
sleep 5
kubectl get service nginx-service

