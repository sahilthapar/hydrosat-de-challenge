# Setup

Note: Instructions have been verified on a Mac OS with Intel chip only. If you face any issues with 
the setup please create a git issue or reach me via email.

## Getting Started
### Setting up a local k8s cluster
#### Pre-requisites

[//]: # (todo: create make commands for all of these)
1. Docker `brew install --cask docker`
2. Minikube (for the k8s cluster) `brew install minikube`
3. Kubectl `brew install kubernetes-cli`
4. Helm `brew install helm`
5. Start docker
6. Start the local k8s cluster
```shell
minikube start
kubectl get nodes
```


