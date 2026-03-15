# Kubernetes Cluster Stack

A production-ready Kubernetes platform deployed with a single command using [Helmfile](https://github.com/helmfile/helmfile). Designed for bare-metal / self-managed clusters.

All configuration is template-driven (`.gotmpl` files) with environment variable substitution via `requiredEnv`, making the stack portable across environments.

The infra base is k3s on AlmaLinux 10 cloud hosts.

## Components

| Category | Component | Description |
|---|---|---|
| **Networking** | [Cilium](https://cilium.io/) | eBPF-based CNI with WireGuard encryption, SPIRE mutual TLS, L2 announcements, Gateway API, and Hubble observability |
| | [Gateway API CRDs](https://gateway-api.sigs.k8s.io/) | Kubernetes Gateway API (experimental channel) |
| | [HAProxy Ingress](https://haproxy-ingress.github.io/) | Ingress controller |
| | [External DNS](https://github.com/kubernetes-sigs/external-dns) | Automatic DNS record management (Cloudflare) |
| **Security** | [cert-manager](https://cert-manager.io/) | Automated TLS certificates with Let's Encrypt (Cloudflare DNS01) |
| | [Sealed Secrets](https://sealed-secrets.netlify.app/) | Encrypted secrets for GitOps workflows |
| | [Tailscale Operator](https://tailscale.com/kb/1236/kubernetes-operator) | VPN integration for secure remote access and API server proxy |
| **Monitoring** | [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) | Prometheus, Grafana, and Alertmanager with custom dashboards (ArgoCD, cert-manager, Envoy, HAProxy, MetalLB) |
| | [Metrics Server](https://github.com/kubernetes-sigs/metrics-server) | Cluster resource metrics |
| | [Headlamp](https://headlamp.dev/) | Kubernetes web UI |
| **Storage** | [Longhorn](https://longhorn.io/) | Distributed block storage |
| | [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) | Local storage for persistent volumes |
| **Databases** | [CloudNativePG](https://cloudnative-pg.io/) | PostgreSQL operator with Barman backup plugin |
| | [MongoDB Kubernetes Operator](https://www.mongodb.com/docs/kubernetes/current/) | MongoDB operator |
| **Logging** | [Graylog](https://graylog.org/) | Centralized log management |
| **GitOps** | [Argo CD](https://argoproj.github.io/cd/) | Continuous delivery |
| **Cluster Ops** | [System Upgrade Controller](https://github.com/rancher/system-upgrade-controller) | Automated host upgrades via Kubernetes-native plans |
| | [Kured](https://kured.dev/) | Safe automatic node reboots |

## Prerequisites

- A running k3s cluster (kubeconfig configured) installed **without** kube-proxy, Flannel, and ServiceLB (Cilium replaces all three)
- [Helmfile](https://github.com/helmfile/helmfile) installed
- [Helm](https://helm.sh/) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed

## Usage

### Full stack install

Set the required environment variables, then run the install script:

```bash
export CILIUM_K8S_SERVICE_HOST=<kubernetes-api-server-host>
export DOMAIN=<your-domain.com>
export LETSENCRYPT_EMAIL=<your-email>
export CLOUDFLARE_API_TOKEN=<cloudflare-api-token>
export TAILSCALE_CLIENT_ID=<tailscale-oauth-client-id>
export TAILSCALE_CLIENT_SECRET=<tailscale-oauth-client-secret>

./install.sh
```

The script validates that all variables are set before running `helmfile sync`.

| Variable | Used by |
|---|---|
| `CILIUM_K8S_SERVICE_HOST` | Cilium (Kubernetes API endpoint) |
| `DOMAIN` | ArgoCD, Cilium resources, Graylog, Headlamp, Grafana, Longhorn (ingress hostnames) |
| `LETSENCRYPT_EMAIL` | cert-manager (ACME account) |
| `CLOUDFLARE_API_TOKEN` | cert-manager (DNS01 solver), External DNS |
| `TAILSCALE_CLIENT_ID` | Tailscale Operator |
| `TAILSCALE_CLIENT_SECRET` | Tailscale Operator |

### Individual components

Install or update a single release:

```bash
helmfile sync -f helm/helmfile.yaml -l name=<release-name>
```

For example:

```bash
helmfile sync -f helm/helmfile.yaml -l name=cilium
helmfile sync -f helm/helmfile.yaml -l name=kube-prometheus-stack
```

## Project Structure

```
helm/
  helmfile.yaml                                 # Root helmfile — includes the four phase files below
  01-helmfile.cni_crds_storage.yaml.gotmpl      # CRDs, CNI, storage, metrics, and ingress
  02-helmfile.dns_cert_security.yaml.gotmpl     # DNS, certificates, and secrets
  03-helmfile.monitoring.yaml.gotmpl            # Prometheus stack, Grafana dashboards, Headlamp
  04-helmfile.system_operations.yaml.gotmpl     # Cluster ops, databases, GitOps, logging, VPN
  <component>/
    values.yaml                                 # Static values
    values.yaml.gotmpl                          # Templated values (env var substitution)
    src/                                        # Supporting files (e.g. Grafana dashboard JSON)

manifests/
  gateway-api-network-policy-demo/              # HTTPRoute + CiliumNetworkPolicy example
  postgres-operator/                            # CloudNativePG cluster, backup, monitoring examples
  tailscale-operator/                           # Tailscale API server proxy configuration

install.sh                                      # One-command installer with env validation
```

## Release Dependencies

Helmfile manages ordering via `needs`. Key dependency chains:

- **Gateway API CRDs** are installed first via a presync hook — Cilium depends on them
- **Prometheus Operator CRDs** are installed as a standalone release — provides ServiceMonitor/PodMonitor CRDs that Cilium and other components depend on
- **Cilium** provisions Gateway, LoadBalancerIPPool, and L2 announcement resources via a dedicated `cilium-resources` release after the CNI is ready
- **cert-manager** deploys cluster issuers as a separate release after the controller is ready
- **External DNS** secrets are deployed before the External DNS release
- **CNPG** deploys the operator first, then the Barman backup plugin
- **MongoDB Operator** installs CRDs via a presync hook before deploying the operator
- **Headlamp** RBAC is deployed as a separate release after Headlamp
- **HAProxy** configuration is deployed as a separate release after the ingress controller
