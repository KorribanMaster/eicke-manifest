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

IMG="eicke-yocto:wrynose"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use host networking: some hosts (and CI sandboxes) cannot create the docker
# bridge veth pair, and host networking is also what `runqemu` wants.
docker build --network host -t "$IMG" "$HERE/docker"

# Allocate a TTY only for an interactive shell (no command args); passing a
# command (e.g. for background/non-interactive runs) must not request a TTY.
tty_flags=(-i)
if [[ $# -eq 0 && -t 0 ]]; then
    tty_flags=(-it)
fi

# KVM acceleration for `runqemu` (needs /dev/kvm). Enable with EICKE_DOCKER_QEMU=1.
kvm_flags=()
if [[ "${EICKE_DOCKER_QEMU:-0}" == "1" ]]; then
    kvm_flags=(--device /dev/kvm)
fi

exec docker run --rm "${tty_flags[@]}" \
    --network host \
    -v "$PWD:/workdir" \
    -v $HOME/yocto/sstate-cache/:/yocto/sstate-cache \
    -v $HOME/yocto/downloads/:/yocto/downloads \
    -v $HOME/yocto/keys/:/yocto/keys \
    "${kvm_flags[@]}" \
    "$IMG" --workdir=/workdir "$@"
