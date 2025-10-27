# Development Secrets

The development kustomize overlay expects two local env files that are **not**
committed to version control:

```
k8s/dev/secrets/postgres.env
k8s/dev/secrets/app.env
```

Create them by copying the examples and updating the values:

```bash
cp k8s/dev/secrets/postgres.env.example k8s/dev/secrets/postgres.env
cp k8s/dev/secrets/app.env.example k8s/dev/secrets/app.env
```

Both files are ignored via `.gitignore`, so each developer can keep personal
credentials without leaking them into the repo.
