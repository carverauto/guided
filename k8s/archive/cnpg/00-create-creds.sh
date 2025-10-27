# Generate new passwords
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '=' | tr '+/' '-_')
GUIDED_PASSWORD=$(openssl rand -base64 32 | tr -d '=' | tr '+/' '-_')

# Create secrets
kubectl create secret generic cluster-pg-superuser \
  --namespace cnpg-system \
  --from-literal=username=postgres \
  --from-literal=password=$POSTGRES_PASSWORD

kubectl create secret generic guided-db-credentials \
  --namespace cnpg-system \
  --from-literal=username=guided \
  --from-literal=password=$GUIDED_PASSWORD
