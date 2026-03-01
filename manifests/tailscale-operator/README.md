# tailscale-operator

Manifests for the Tailscale Kubernetes operator.

| File | Description |
|---|---|
| `apiserver_proxygroup.yaml` | `ProxyGroup` that exposes the Kubernetes API server via Tailscale (auth mode, 2 replicas) |

## Required environment variables

None. These manifests contain no variable placeholders and can be applied directly.

## Deploying

```sh
kubectl apply -f apiserver_proxygroup.yaml
```
