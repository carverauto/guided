# Guided Kubernetes deployment

This directory contains Kustomize overlays for running the Phoenix + AGE stack
in different environments.

## Structure

- `base/` – namespace, Apache AGE StatefulSet, Phoenix deployment/services, and
  config maps common to all environments. Requires the secrets
  `guided-postgres-secret` and `guided-app-secret` to already exist.
- `dev/` – convenience overlay that generates development credentials with
  `secretGenerator`. Create the local env files under `k8s/dev/secrets/`
  (see the README in that directory) before running `kustomize build`.
- `staging/` and `prod/` – production-style overlays that expect Bitnami
  SealedSecrets to supply credentials. Each overlay includes ingress
  configuration and image tag overrides.
- `archive/` – deprecated manifests kept for reference (e.g. the original
  CNPG attempt).

## Managing secrets with SealedSecrets

1. Install the Bitnami SealedSecrets controller in the cluster (for example via
   Helm):

   ```bash
   helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
   helm install sealed-secrets sealed-secrets/sealed-secrets \
     --namespace sealed-secrets --create-namespace
   ```

2. Run the helper script to generate sealed secrets for the desired overlay:

   ```bash
   scripts/k8s/seal_secrets.sh staging   # or prod
   ```

   The script prompts for database/application passwords, produces freshly
   generated `SECRET_KEY_BASE`/`RELEASE_COOKIE` values, and writes sealed
   manifests to `k8s/<env>/secrets/`.

Once committed, GitOps will ensure the controller creates the underlying
Kubernetes secrets during deployment.

## Building and publishing container images

Application image:

```bash
scripts/docker/build_release_image.sh staging --push
scripts/docker/build_release_image.sh prod --push

# or via Makefile shortcuts
make image-push-staging
make image-push-prod
```

The script builds from `Dockerfile`, tags the image as
`ghcr.io/carverauto/guided/web:<tag>`, and optionally pushes when `--push` is
provided. Set `GHCR_USER`/`GHCR_TOKEN` before pushing.

PostgreSQL + AGE image (for the CloudNativePG overlays):

```bash
scripts/docker/build_postgres_age_image.sh latest --push

# or via Makefile shortcut
make postgres-image-push
```

The resulting image is referenced by the CloudNativePG cluster manifests as
`ghcr.io/carverauto/guided/postgres-age:latest`. Use a versioned tag in place
of `latest` when you promote to production.

If the cluster cannot pull from GHCR anonymously, create an image pull secret
and attach it to the default service account:

```bash
kubectl create secret docker-registry ghcr-creds \
  --namespace guided \
  --docker-server=ghcr.io \
  --docker-username="$GHCR_USER" \
  --docker-password="$GHCR_TOKEN"

kubectl patch serviceaccount default \
  -n guided \
  --type merge \
  -p '{"imagePullSecrets":[{"name":"ghcr-creds"}]}'
```

## Smoke testing the MCP endpoint

After applying an overlay, verify both the web app and the MCP service:

Run the smoke-test helper (or the Make wrapper) to confirm both ingress and the MCP
LoadBalancer are reachable:

```bash
scripts/k8s/smoke_mcp.sh --ingress-host staging.guided.dev

# or
make smoke-staging
```

The script fetches the LoadBalancer IP, performs an MCP initialization call,
and (optionally) issues a HEAD request against the ingress host.

## Installing CloudNativePG

For the high-availability database overlays you need the CloudNativePG
operator installed in the cluster. A minimal Helm-based installation is:

```bash
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update
helm install cnpg cnpg/cloudnative-pg \
  --namespace cnpg-system --create-namespace
```

Wait until the `cnpg-controller-manager` deployment reports `AVAILABLE` before
deploying the CNPG-backed overlays.

## High-availability database overlays

The directories `k8s/staging-cnpg` and `k8s/prod-cnpg` extend their
environment counterparts by:

- Scaling the standalone `guided-postgres` StatefulSet to zero replicas
- Re-pointing the `guided-postgres` service at the CNPG primary pod
- Creating a three-instance CloudNativePG `Cluster` named `guided-db`

Apply the staging overlay after pushing both container images:

```bash
kubectl apply -k k8s/staging-cnpg
```

Connectivity for the Phoenix app continues to run through the
`guided-postgres` service; the CNPG cluster exposes the standard `-rw`/`-ro`
services (for example `guided-db-rw`) for administrative access.
