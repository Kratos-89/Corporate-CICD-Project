#!/bin/bash
# Script to delete Kubernetes manifests in reverse order

set -e

echo "Deleting Deployment and Service..."
kubectl delete -f kube-files/deployments.yaml || true

echo "Deleting Secret..."
kubectl delete -f kube-files/jenkinsSecret.yaml || true

echo "Deleting RoleBinding..."
kubectl delete -f kube-files/svcrolebind.yaml || true

echo "Deleting Role..."
kubectl delete -f kube-files/svcrole.yaml || true

echo "Deleting ServiceAccount..."
kubectl delete -f kube-files/svcacc.yaml || true

echo "All resources deleted (if they existed)."
