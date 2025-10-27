# Production secrets

Generate sealed versions of the database and Phoenix secrets before applying
the production overlay. The helper script automates the process and now also
populates the `username`/`password` keys expected by the CloudNativePG
manifests:

```bash
scripts/k8s/seal_secrets.sh prod
```

This prompts for the required values and produces `SealedSecret` manifests in
this directory. Ensure the SealedSecrets controller is running in the cluster.
