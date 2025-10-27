#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'DOC'
Usage: scripts/docker/build_postgres_age_image.sh <tag> [--push]

Builds the CloudNativePG-compatible PostgreSQL image with the Apache AGE
extension. Pass --push to publish to ghcr.io/carverauto/guided/postgres-age:<tag>.

Environment variables:
  BUILD_ARGS    Additional docker build arguments (optional)
  AGE_VERSION   Git branch or tag to build (default release/PG16/1.6.0)
  BUILDER_IMAGE Debian image for compilation (default debian:bullseye-slim)
  CNPG_IMAGE    Base CloudNativePG image (default ghcr.io/cloudnative-pg/postgresql:16.4-7)
  PLATFORM      Target platform (default: linux/amd64)
  GHCR_USER     Username for docker login (required when using --push)
  GHCR_TOKEN    Personal access token for docker login (required when using --push)
DOC
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TAG="$1"
shift

PUSH_IMAGE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --push)
      PUSH_IMAGE=true
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
IMAGE_NAME="ghcr.io/carverauto/guided/postgres-age:${TAG}"
PLATFORM="${PLATFORM:-linux/amd64}"

BUILD_ARGS_COMBINED=( ${BUILD_ARGS:-} \
  --build-arg "AGE_VERSION=${AGE_VERSION:-release/PG16/1.6.0}" \
  --build-arg "BUILDER_IMAGE=${BUILDER_IMAGE:-debian:bullseye-slim}" \
  --build-arg "CNPG_IMAGE=${CNPG_IMAGE:-ghcr.io/cloudnative-pg/postgresql:16.4-7}" )

echo "Building ${IMAGE_NAME} for ${PLATFORM}"

BUILD_CMD=(docker buildx build --platform "${PLATFORM}" -f "${REPO_ROOT}/Dockerfile.postgres-age" -t "${IMAGE_NAME}")
BUILD_CMD+=("${BUILD_ARGS_COMBINED[@]}")

if [[ "${PUSH_IMAGE}" == "true" ]]; then
  if [[ -z "${GHCR_USER:-}" || -z "${GHCR_TOKEN:-}" ]]; then
    echo "GHCR_USER and GHCR_TOKEN must be set to push images." >&2
    exit 1
  fi

  echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USER}" --password-stdin
  BUILD_CMD+=(--push "${REPO_ROOT}")
else
  BUILD_CMD+=(--load "${REPO_ROOT}")
fi

"${BUILD_CMD[@]}"
