#!/bin/bash
# Script to apply Kubernetes manifests in the correct order

set -e

echo "Applying ServiceAccount..."
kubectl apply -f kube-files/svcacc.yaml

echo "Applying Role..."
kubectl apply -f kube-files/svcrole.yaml

echo "Applying RoleBinding..."
kubectl apply -f kube-files/svcrolebind.yaml

echo "Applying Secret..."
kubectl apply -f kube-files/jenkinsSecret.yaml

echo "Applying Deployment and Service..."
kubectl apply -f kube-files/deployments.yaml

echo "All resources applied successfully."
