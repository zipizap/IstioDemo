# IstioDemo
Isto demo in a kind-cluster inside an Azure-VM

# Create, configure and login into new azure VM
```
az login

git clone https://github.com/zipizap/IstioDemo.git
cd IstioDemo


# Delete (if exists) RG "rg-istiodemo", and then re-create it from scratch containing a vnet+subnet+nsg and VM where cloudinit will install docker,kubectl,helm,k9s and kind
# The VM is left ready for a user to login via ssh, and use "kind" to create a new kubernetes cluster over docker
./dep.destroyRg_and_startFromScratch.sh


# Ssh-login into VM 
./pdep.ssh.vm.sh
```


# Istio-Demo inside the VM

Inside the VM, do:

```
# Create kubernetes cluster with kind (over docker)
kind create cluster
kubectl get pod -A




```





