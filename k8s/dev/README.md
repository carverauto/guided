# Dev overlay

Applies the base manifests together with development-only secrets generated via
`secretGenerator`. Use this overlay for local clusters that do not support
SealedSecrets.

```bash
kubectl apply -k k8s/dev
```

Do not use these credentials in shared environments.
