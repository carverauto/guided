#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/k8s/seal_secrets.sh <environment>

Creates Bitnami SealedSecrets for the specified overlay (staging or prod).
The script prompts for the database password and guided app password, then
generates sealed manifests inside k8s/<environment>/secrets/.

Environment variables:
  SEALED_NAMESPACE   Namespace of the sealed-secrets controller (default: sealed-secrets)
  SEALED_CONTROLLER  Name of the sealed-secrets controller (default: sealed-secrets)
  SEALED_CERT        Path to a PEM-encoded controller certificate (optional)
  KUBE_NAMESPACE     Namespace for the Guided deployment (default: guided)
EOF
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

ENVIRONMENT="$1"
ALLOWED_ENVS=("staging" "prod")
if [[ ! " ${ALLOWED_ENVS[*]} " =~ " ${ENVIRONMENT} " ]]; then
  echo "Environment must be one of: ${ALLOWED_ENVS[*]}" >&2
  exit 1
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd kubectl
require_cmd kubeseal
require_cmd openssl
require_cmd mix

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OVERLAY_DIR="${REPO_ROOT}/k8s/${ENVIRONMENT}"
SECRET_DIR="${OVERLAY_DIR}/secrets"

if [[ ! -d "${OVERLAY_DIR}" ]]; then
  echo "Overlay directory ${OVERLAY_DIR} not found." >&2
  exit 1
fi

mkdir -p "${SECRET_DIR}"

SEALED_NAMESPACE="${SEALED_NAMESPACE:-sealed-secrets}"
SEALED_CONTROLLER="${SEALED_CONTROLLER:-sealed-secrets}"
SEALED_CERT="${SEALED_CERT:-}"
KUBE_NAMESPACE="${KUBE_NAMESPACE:-guided}"

read -r -s -p "PostgreSQL password: " POSTGRES_PASSWORD
echo
read -r -s -p "Guided app password (leave blank to reuse database password): " GUIDED_APP_PASSWORD
echo
if [[ -z "${GUIDED_APP_PASSWORD}" ]]; then
  GUIDED_APP_PASSWORD="${POSTGRES_PASSWORD}"
fi

pushd "${REPO_ROOT}/guided" >/dev/null
SECRET_KEY_BASE="$(mix phx.gen.secret)"
popd >/dev/null

RELEASE_COOKIE="$(openssl rand -hex 32)"

TMP_POSTGRES="$(mktemp)"
TMP_APP="$(mktemp)"

cleanup() {
  rm -f "${TMP_POSTGRES}" "${TMP_APP}"
}
trap cleanup EXIT

kubectl create secret generic guided-postgres-secret \
  --namespace "${KUBE_NAMESPACE}" \
  --from-literal=POSTGRES_USER=postgres \
  --from-literal=POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
  --from-literal=POSTGRES_DB=guided \
  --from-literal=GUIDED_APP_USER=guided \
  --from-literal=GUIDED_APP_PASSWORD="${GUIDED_APP_PASSWORD}" \
  --from-literal=username=postgres \
  --from-literal=password="${POSTGRES_PASSWORD}" \
  --dry-run=client -o yaml > "${TMP_POSTGRES}"

kubectl create secret generic guided-app-secret \
  --namespace "${KUBE_NAMESPACE}" \
  --from-literal=SECRET_KEY_BASE="${SECRET_KEY_BASE}" \
  --from-literal=RELEASE_COOKIE="${RELEASE_COOKIE}" \
  --dry-run=client -o yaml > "${TMP_APP}"

KUBESEAL_ARGS=(--format yaml)
if [[ -n "${SEALED_CERT}" ]]; then
  KUBESEAL_ARGS+=(--cert "${SEALED_CERT}")
else
  KUBESEAL_ARGS+=(--controller-namespace "${SEALED_NAMESPACE}" --controller-name "${SEALED_CONTROLLER}")
fi

kubeseal "${KUBESEAL_ARGS[@]}" < "${TMP_POSTGRES}" > "${SECRET_DIR}/guided-postgres-secret.yaml"
kubeseal "${KUBESEAL_ARGS[@]}" < "${TMP_APP}" > "${SECRET_DIR}/guided-app-secret.yaml"

echo "Sealed secrets written to ${SECRET_DIR}"
