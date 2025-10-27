# guided base manifests

This base kustomization provisions the shared `guided` namespace, a
single-node PostgreSQL instance with the Apache AGE extension enabled,
and a Phoenix deployment with matching services. Secrets for the
database and Phoenix release must be provided by the overlay (for
example via SealedSecrets or another secret management workflow).

## Applying

```bash
kustomize build k8s/base | kubectl apply -f -
```

On first boot the container initialisation scripts create the `guided`
role/database, load the `age` library, create the `age` extension, and update
the default search path so the application can immediately run Cypher queries.
