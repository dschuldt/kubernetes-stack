# Kubernetes Cluster Stack

A production-ready Kubernetes platform deployed with a single command using [Helmfile](https://github.com/helmfile/helmfile). Designed for bare-metal / self-managed clusters.

All configuration is template-driven (`.gotmpl` files) with environment variable substitution, making the stack portable across environments.

The infra base is k3s on Almalinux 10 cloud hosts.

## Components

| Category | Component | Description |
|---|---|---|
| **Networking** | [Cilium](https://cilium.io/) | eBPF-based CNI with WireGuard encryption, SPIRE mutual TLS, L2 announcements, Gateway API, and Hubble observability |
| | [Gateway API CRDs](https://gateway-api.sigs.k8s.io/) | Kubernetes Gateway API (experimental channel) |
| | [HAProxy Ingress](https://haproxy-ingress.github.io/) | Ingress controller |
| | [External DNS](https://github.com/kubernetes-sigs/external-dns) | Automatic DNS record management (Cloudflare) |
| **Security** | [cert-manager](https://cert-manager.io/) | Automated TLS certificates with Let's Encrypt cluster issuers |
| | [Sealed Secrets](https://sealed-secrets.netlify.app/) | Encrypted secrets for GitOps workflows |
| | [Tailscale Operator](https://tailscale.com/kb/1236/kubernetes-operator) | VPN integration for secure remote access |
| **Monitoring** | [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) | Prometheus, Grafana (with custom dashboards), and Alertmanager |
| | [Metrics Server](https://github.com/kubernetes-sigs/metrics-server) | Cluster resource metrics |
| | [Headlamp](https://headlamp.dev/) | Kubernetes web UI |
| **Storage** | [Longhorn](https://longhorn.io/) | Distributed block storage |
| | [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) | Local storage for persistent volumes |
| **Databases** | [CloudNativePG](https://cloudnative-pg.io/) | PostgreSQL operator with Barman backup plugin |
| **GitOps** | [Argo CD](https://argoproj.github.io/cd/) | Continuous delivery |
| **Cluster Ops** | [System Upgrade Controller](https://github.com/rancher/system-upgrade-controller) | Automated host upgrades via Kubernetes-native plans |
| | [Kured](https://kured.dev/) | Safe automatic node reboots |

## Prerequisites

- A running Kubernetes cluster (kubeconfig configured) without kube-proxy (Cilium will take care of that)
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
  helmfile.yaml              # Main Helmfile orchestrating all releases
  <component>/               # Per-component values files
    values.yaml              # Static values
    values.yaml.gotmpl       # Templated values (env var substitution via requiredEnv)
manifests/
  gateway-api-network-policy-demo/  # HTTPRoute + CiliumNetworkPolicy example
  postgres-operator/                # CloudNativePG examples (cluster, backup, monitoring)
  tailscale-operator/               # Tailscale API server proxy configuration
install.sh                   # One-command installer with env validation
```

## Release Dependencies

Helmfile manages ordering via `needs`. Key dependency chains:

- **Gateway API CRDs** are installed first via a presync hook -- Cilium and cert-manager both depend on it
- **kube-prometheus-stack** is deployed early -- Metrics Server, Sealed Secrets, CNPG, and HAProxy depend on it for ServiceMonitor CRDs
- **cert-manager** deploys cluster issuers as a separate release after the controller is ready
- **Cilium** provisions Gateway, LoadBalancerIPPool, and L2 announcement resources via a dedicated `cilium-resources` release after the CNI is ready
- **CNPG** deploys the operator first, then the Barman backup plugin
