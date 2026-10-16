#!/bin/sh

# The script requires:
# - rockcraft
# - skopeo (from rockcraft snap)
# - yq
# - podman

set -e

SKOPEO="/snap/rockcraft/current/bin/skopeo"
if [ ! -x "$SKOPEO" ]; then
  SKOPEO="skopeo"
fi

IMAGE="${IMAGE:-secure-token-service:dev}"
ARCH="${ARCH:-$(dpkg --print-architecture 2>/dev/null || true)}"
: "${ARCH:=$(go env GOARCH 2>/dev/null || true)}"
case "$ARCH" in
  amd64|arm64) ;;
  *)
    echo "unsupported rock arch: $ARCH" >&2
    exit 1
    ;;
esac
VERSION=$(yq -r '.version' rockcraft.yaml)
ROCK_FILE="secure-token-service_${VERSION}_${ARCH}.rock"

rockcraft clean
rockcraft pack -v --platform "${ARCH}"

echo "$IMAGE built"

# Load into podman for local container-structure-tests
if command -v podman >/dev/null 2>&1; then
  podman load -i "$ROCK_FILE"
  podman tag "localhost/${VERSION}:latest" "$IMAGE"
fi

if [ "${PUSH_IMAGE}" = "true" ]; then
  $SKOPEO --insecure-policy copy "oci-archive:${ROCK_FILE}" "docker://$IMAGE"
  echo "$IMAGE pushed"
fi


