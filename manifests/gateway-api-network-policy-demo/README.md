# gateway-api-network-policy-demo

Deploys an nginx demo app exposed via a Cilium Gateway API `HTTPRoute` with a `CiliumNetworkPolicy` restricting ingress.

## Required environment variables

| Variable | Description |
|---|---|
| `HTTPROUTE_HOSTNAME` | The hostname used in the `HTTPRoute` (e.g. `nginx-demo.example.com`) |

## Deploying with envsubst

Export the variable, then pipe each manifest through `envsubst` before applying:

```sh
export HTTPROUTE_HOSTNAME=nginx-demo.example.com

envsubst < nginx-demo.yaml | kubectl apply -f -
```

To apply all manifests in this folder at once:

```sh
export HTTPROUTE_HOSTNAME=nginx-demo.example.com

for f in *.yaml; do envsubst < "$f" | kubectl apply -f -; done
```
