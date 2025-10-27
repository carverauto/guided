# Staging secrets

These manifests are placeholders for Bitnami SealedSecrets. The recommended
workflow is to run the helper script, which prompts for passwords and writes
sealed output into this directory (the script now also adds the `username` and
`password` keys required by CloudNativePG):

```bash
scripts/k8s/seal_secrets.sh staging
```

If you prefer to seal secrets manually, make sure the SealedSecrets controller
is running and replace the `Ag==` values with real encrypted payloads using
`kubeseal`.
