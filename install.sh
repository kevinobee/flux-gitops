#!/bin/bash
# install.sh - create k8s cluster and install GitOps applications

# standard bash error handling
set -o errexit;
set -o pipefail;
set -o nounset;
# debug commands
# set -x;

# Homebrew on Linux - ref: https://brew.sh/
if [ ! $(which brew) ]; then
  (
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  )
fi

brewTools=( \
  "kind" \
  "fluxcd/tap/flux" \
  "linkerd" \
  "octant"
)

for i in "${brewTools[@]}"
do
  if [[ ! $(brew info "${i}") ]]; then
    echo "Installing ${i} CLI ... "
    brew install ${i} -q
  fi
done

if [ ! $(kind get clusters --quiet) ]; then
  kind create cluster --config kind-config.yaml --wait 1m
  kubectl wait node --all --for condition=ready
fi
kubectl cluster-info

echo
echo "Install Flux ..."
flux check --pre
flux install --namespace=flux-system

echo
echo "Install GitOps manifests ..."
kubectl apply -k gitops/flux/runtime/manifests

# kubectl apply -f gitops/flux/apps/manifests/apps.yaml

echo
linkerd check

echo
echo
echo "To open the Linkerd UI run:"
echo
echo "linkerd viz dashboard"
echo
echo
echo "To install useful CLI tools run:"
echo
echo "brew install kubectx kubeseal"
echo
echo
echo "To manually install applications into the cluster run:"
echo
echo "kubectl kustomize --enable-helm apps | k apply -f -"
echo
