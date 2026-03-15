# postgres-operator

Manifests for a CloudNativePG cluster with MinIO-backed WAL archiving and scheduled backups.

| File | Description |
|---|---|
| `secrets.yaml` | Credentials for the cluster bootstrap user and MinIO S3 access |
| `objectstore.yaml` | Barman `ObjectStore` pointing at MinIO |
| `cluster.yaml` | CloudNativePG `Cluster` (PostgreSQL 18, 2 instances) |
| `backup.yaml` | Daily `ScheduledBackup` via the barman-cloud plugin |
| `monitoring.yaml` | `PodMonitor` for Prometheus scraping |

## Required environment variables

### objectstore.yaml

| Variable | Description |
|---|---|
| `S3_ENDPOINT_URL` | S3-compatible endpoint URL for MinIO (e.g. `http://minio.example.com`) |

### secrets.yaml

| Placeholder | Description |
|---|---|
| `ACCESS_KEY_ID_B64` | Base64-encoded MinIO access key ID |
| `ACCESS_SECRET_KEY_B64` | Base64-encoded MinIO secret access key |
| `REGION_B64` | Base64-encoded S3 region name |

Generate base64 values with:

```sh
echo -n 'your-value' | base64
```

## Deploying with envsubst

Export the variable and substitute before applying `objectstore.yaml`:

```sh
export S3_ENDPOINT_URL=http://minio.example.com

envsubst < objectstore.yaml | kubectl apply -f -
```

To apply all manifests in the correct order (fill in `secrets.yaml` placeholders first):

```sh
export S3_ENDPOINT_URL=http://minio.example.com

kubectl apply -f secrets.yaml
envsubst < objectstore.yaml | kubectl apply -f -
kubectl apply -f cluster.yaml
kubectl apply -f backup.yaml
kubectl apply -f monitoring.yaml
```
