
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest

kubectl create namespace cattle-system

kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.1/cert-manager.crds.yaml

helm repo add jetstack https://charts.jetstack.io

helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.5.1

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml


helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=167.235.53.130.sslip.io \
  --set replicas=1 \
  --set bootstrapPassword=MySuperSecureAdminPW

helm delete rancher --namespace cattle-system