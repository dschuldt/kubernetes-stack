#!/bin/bash

set -euo pipefail

if [[ ! -n "${CILIUM_K8S_SERVICE_HOST:-}" ]]; then
    echo "Variable CILIUM_K8S_SERVICE_HOST is empty or not set"
    exit 1
fi

if [[ ! -n "${DOMAIN:-}" ]]; then
    echo "Variable DOMAIN is empty or not set"
    exit 1
fi

if [[ ! -n "${LETSENCRYPT_EMAIL:-}" ]]; then
    echo "Variable LETSENCRYPT_EMAIL is empty or not set"
    exit 1
fi

if [[ ! -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
    echo "Variable CLOUDFLARE_API_TOKEN is empty or not set"
    exit 1
fi

if [[ ! -n "${TAILSCALE_CLIENT_ID:-}" ]]; then
    echo "Variable TAILSCALE_CLIENT_ID is empty or not set"
    exit 1
fi

if [[ ! -n "${TAILSCALE_CLIENT_SECRET:-}" ]]; then
    echo "Variable TAILSCALE_CLIENT_SECRET is empty or not set"
    exit 1
fi

helmfile sync -f helm/helmfile.yaml
