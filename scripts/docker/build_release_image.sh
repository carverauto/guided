#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/docker/build_release_image.sh <tag> [--push]

Builds the Phoenix release image using the repository Dockerfile. Pass --push
to push the resulting image to ghcr.io/carverauto/guided/web:<tag>.

Environment variables:
  BUILD_ARGS    Additional docker build arguments (optional)
  PLATFORM      Target platform (default: linux/amd64)
  GHCR_USER     Username for docker login (required when using --push)
  GHCR_TOKEN    Personal access token for docker login (required when using --push)
EOF
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
IMAGE_NAME="ghcr.io/carverauto/guided/web:${TAG}"
PLATFORM="${PLATFORM:-linux/amd64}"

declare -a EXTRA_BUILD_ARGS=()
if [[ -n "${BUILD_ARGS:-}" ]]; then
  # shellcheck disable=SC2206
  EXTRA_BUILD_ARGS=(${BUILD_ARGS})
fi

echo "Building ${IMAGE_NAME} for ${PLATFORM}"

BUILD_CMD=(docker buildx build --platform "${PLATFORM}" -f "${REPO_ROOT}/Dockerfile" -t "${IMAGE_NAME}")

if (( ${#EXTRA_BUILD_ARGS[@]} )); then
  BUILD_CMD+=("${EXTRA_BUILD_ARGS[@]}")
fi

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
