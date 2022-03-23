# IstioDemo
Isto demo in a kind-cluster inside an Azure-VM

# Istio Lab Setup

## Create, configure and login into new azure VM
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


## Create kubernetes cluster:

Inside the VM

```
# Create kubernetes cluster with kind (over docker)
kind create cluster
kubectl get pod -A

```

## Install istio and addons

```
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.13.2
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y

# Enable namespace-auto-injection for default ns
kubectl label namespace default  istio-injection=enabled
kubectl get namespaces --label-columns=istio-injection

# Install addons: kiali, prometheus, etc
kubectl apply -f samples/addons
kubectl rollout status deployment/kiali -n istio-system

```

## Install an app prepared for istio

```
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml

# Check app services, and pods with auto-injected sidecar 2/2
kubectl get services
timeout 60 watch kubectl get pods
kubectl describe pod pod-with-sidecar

# Check: pod can connect to the app via service productpage:9080
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"

# Expose app via Gateway + VirtualService
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl get service,gateway,virtualservice

# Check: from outside the cluster (from VM), we can connect to the app http://...../productpage
# via istio-ingressgateway > Gateway > VirtualService > Service > Deployment > Pod
#
#
# NOTE: We use the IngressGW_NodePort_ip/port to connect to the istio-ingressgateway instead of the normal external-loadbalancer, because this kind setup is simpler (no external-load-balancer). 
# However, if you want an external-lb (as metallb) refer to https://istio.io/latest/docs/setup/platform-setup/kind/#installation-steps
#
export IngressGW_NodePort_Ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-control-plane)
export IngressGW_NodePort_Port=$(kubectl -n istio-system get service/istio-ingressgateway  -o 'jsonpath={.spec.ports[?(@.name=="http2")].nodePort}')
curl  http://$IngressGW_NodePort_Ip:$IngressGW_NodePort_Port/productpage | grep -o "<title>.*</title>"

# In your laptop ssh-session, add a Local-port-forward-tunnel
#  - source-port:          <IngressGW_NodePort_Port>
#  - destination ip:port   <IngressGW_NodePort_Ip>:<IngressGW_NodePort_Port>
#
# And then in your laptop open chrome tab to the application webpage
#
#  http://127.0.0.1:<IngressGW_NodePort_Port>/productpage
#
# and the web-application should load in chrome


```


# Istio demo

## Open Istio dashboards

### Kiali
- In VM, leave a shell open running: `kubectl proxy`
- In laptop ssh-session, add Local-port-forwarding-tunnel:
  - source-port:          8001
  - destination ip:port   127.0.0.1:8001
- In laptop, open chrome tab to http://localhost:8001/api/v1/namespaces/istio-system/services/http:kiali:20001/proxy/


### Grafana
- In VM, leave a shell open running: `kubectl -n istio-system port-forward service/grafana 8002:3000`
- In laptop ssh-session, add Local-port-forwarding-tunnel:
  - source-port:          8002
  - destination ip:port   127.0.0.1:8002
- In laptop, open chrome tab to http://localhost:8002/d/G8wLrJIZk/istio-mesh-dashboard?orgId=1&refresh=5s&from=now-1h&to=now

### Jaeger
- In laptop, open chrome tab to http://localhost:8001/api/v1/namespaces/istio-system/services/http:tracing:80/proxy/jaeger/search



## Understand core resources and concepts

- Understand sidecar auto-injection via namespace label (and exclusion)

- Understand Gateway and VirtualService, etc

```
# 1 nginx-controller + N Ingress + M Services = 1 Gateway + N VirtualService + M Services: https://rinormaloku.com/istio-practice-routing-virtualservices/
#
# Resume gw, virtualservice, destinationRule: https://medium.com/google-cloud/istio-routing-basics-14feab3c040e
#
#   . ingressgateway  -  Gateway - VirtualService - (DestinationRule: subsets) - Services  -  Deployment    -    Pod
#     lb: external-ip
#                        tcp/80
#                        hosts     hosts
#                                  paths
#                                                    subsets (host:mySvc;version:)                               app: myApp
#                                                                                                                version: v1/2
#
#    *virtualservices* glues *gateway* with *services*
#    *destinationrule* defines *subsets* (from pod-label version:) which can be used by virtualServices
```


- Understand app resources

```
istio-ingressgateway (lb) 

Gateway: bookinfo-gateway 
  - host, port 

VirtualService: 
  - host, path

Service 

Deployment
```

- Tour Kiali dashboard

- Tour Grafana dashboard (understand underlying prometheus)

- Tour Jaeger distributed-tracing

- Understand mTLS (intra-mesh, can be mandatory)


