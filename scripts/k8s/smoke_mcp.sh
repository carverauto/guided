#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="guided"
SERVICE="guided-mcp"
INGRESS_HOST=""
INGRESS_SCHEME="https"
HTTP_PATH="/"

usage() {
  cat <<'EOF'
Usage: scripts/k8s/smoke_mcp.sh [options]

Options:
  -n, --namespace <name>     Kubernetes namespace (default: guided)
  -s, --service <name>       LoadBalancer service exposing MCP (default: guided-mcp)
      --ingress-host <host>  Optional ingress hostname to probe (e.g. staging.guided.dev)
      --ingress-scheme <s>   Scheme for ingress probe (default: https)
      --path <path>          HTTP path to hit on Phoenix ingress (default: /)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    -s|--service)
      SERVICE="$2"
      shift 2
      ;;
    --ingress-host)
      INGRESS_HOST="$2"
      shift 2
      ;;
    --ingress-scheme)
      INGRESS_SCHEME="$2"
      shift 2
      ;;
    --path)
      HTTP_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

for cmd in kubectl curl jq; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}" >&2
    exit 1
  fi
done

echo "Fetching load balancer IP for service ${SERVICE} in namespace ${NAMESPACE}..."
LB_IP="$(kubectl get svc "${SERVICE}" -n "${NAMESPACE}" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"

if [[ -z "${LB_IP}" ]]; then
  echo "LoadBalancer IP not available yet. Check service status with:" >&2
  echo "  kubectl get svc ${SERVICE} -n ${NAMESPACE}" >&2
  exit 1
fi

echo "LoadBalancer IP: ${LB_IP}"

MCP_RESPONSE="$(mktemp)"
trap 'rm -f "${MCP_RESPONSE}"' EXIT

HTTP_CODE=$(curl -sS -o "${MCP_RESPONSE}" -w "%{http_code}" \
  "http://${LB_IP}:4000/mcp" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","clientInfo":{"name":"smoke-test","version":"0.1.0"}}}')

if [[ "${HTTP_CODE}" != "200" && "${HTTP_CODE}" != "202" ]]; then
  echo "MCP endpoint returned HTTP ${HTTP_CODE}" >&2
  cat "${MCP_RESPONSE}" >&2
  exit 1
fi

echo "MCP endpoint responded with HTTP ${HTTP_CODE}:"
cat "${MCP_RESPONSE}" | jq .

if [[ -n "${INGRESS_HOST}" ]]; then
  echo
  echo "Probing ingress at ${INGRESS_SCHEME}://${INGRESS_HOST}${HTTP_PATH}"
  curl -Ik "${INGRESS_SCHEME}://${INGRESS_HOST}${HTTP_PATH}"
fi
