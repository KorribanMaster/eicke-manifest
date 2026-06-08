#!/usr/bin/env bash
#
# Build the Yocto build container and drop into a shell (or run a command)
# with the current directory bind-mounted at /workdir.
#
# Usage:
#   cd <your empty workspace>
#   /path/to/eicke-manifest/dock.sh                 # interactive shell
#   /path/to/eicke-manifest/dock.sh bitbake eicke-image   # run a command
#
# The host only needs Docker + git; all Yocto tooling lives in the container.
set -euo pipefail

IMG="eicke-yocto:scarthgap"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker build -t "$IMG" "$HERE/docker"

# Extra flags useful for `runqemu` inside the container (KVM acceleration and
# host networking). Enable by exporting EICKE_DOCKER_QEMU=1.
qemu_flags=()
if [[ "${EICKE_DOCKER_QEMU:-0}" == "1" ]]; then
    qemu_flags=(--device /dev/kvm --network host)
fi

exec docker run --rm -it \
    -v "$PWD:/workdir" \
    "${qemu_flags[@]}" \
    "$IMG" --workdir=/workdir "$@"
