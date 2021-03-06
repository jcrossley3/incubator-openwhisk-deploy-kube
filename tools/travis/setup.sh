# This script assumes Docker is already installed
#!/bin/bash

set -x

# set docker0 to promiscuous mode
sudo ip link set docker0 promisc on

# Download and install kubectl and minikube following the recipe in the minikube
# project README.md for using minikube for Linux Continuous Integration with VM Support
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$TRAVIS_KUBE_VERSION/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin
curl -Lo minikube https://storage.googleapis.com/minikube/releases/$TRAVIS_MINIKUBE_VERSION/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin

export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_HOME=$HOME
export CHANGE_MINIKUBE_NONE_USER=true
mkdir $HOME/.kube || true
touch $HOME/.kube/config

export KUBECONFIG=$HOME/.kube/config
sudo -E /usr/local/bin/minikube start --vm-driver=none --kubernetes-version=$TRAVIS_KUBE_VERSION

# Wait until kubectl can access the api server that Minikube has created
TIMEOUT=0
TIMEOUT_COUNT=60
until $( /usr/local/bin/kubectl get po &> /dev/null ) || [ $TIMEOUT -eq $TIMEOUT_COUNT ]; do
  echo "minikube is not up yet"
  let TIMEOUT=TIMEOUT+1
  sleep 5
done

if [ $TIMEOUT -eq $TIMEOUT_COUNT ]; then
  echo "Failed to start minikube"
  exit 1
fi

echo "minikube is deployed and reachable"

# set the invoker label
kubectl label nodes --all openwhisk=invoker
