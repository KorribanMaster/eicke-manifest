# eicke-manifest

A [`repo`](https://gerrit.googlesource.com/git-repo) manifest that assembles a
reproducible Yocto build for a basic **wrynose (6.0 LTS)** x86-64 image with:

- a custom **`eicke` distro** (systemd-based)
- **GRUB-EFI** bootloader
- a custom **WIC image with an A/B (dual-copy) rootfs layout**
- **SWUpdate** for image updates (local `.swu`, applied via CLI / USB / web UI)

As of 6.0, the Yocto Project no longer ships the combined **poky** repo for new
releases, so this manifest assembles the build from the individual upstream
layers (**bitbake**, **openembedded-core**, **meta-yocto**) instead of poky, and
uses the custom `eicke` distro rather than the poky reference distro.

The build runs **inside a Docker container** (based on the official
[`crops/poky`](https://hub.docker.com/r/crops/poky) image) because the layer is
intended to be built from hosts that Yocto does not officially support (e.g.
Arch Linux). The host only needs **Docker** and **git**. (The `crops/poky`
container is just a build host with the right dependencies; it does not contain
the poky metadata.)

## Prerequisites

Install the [`repo`](https://gerrit.googlesource.com/git-repo) tool:

```shell
# assuming ~/.local/bin/ exists and is on your PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.local/bin/repo
chmod a+rx ~/.local/bin/repo
```

You also need **Docker**, **git**, and an **SSH key with access to the (private)
repos** (the manifest fetches over SSH).

## Manifest layout

Manifests live under `manifests/`, grouped by maturity:

| Path | Purpose |
|---|---|
| `manifests/experimental/` | Bleeding-edge / in-progress manifests. Track upstream release branches and may pin our own layers to feature branches. **Not** guaranteed to build. |
| `manifests/integration/` | Manifests under validation — known-good or being qualified before a release. |
| `manifests/releases/` | Stable, fully pinned manifests for shipped releases (layers pinned to tags / explicit SRCREVs for reproducibility). |

- `default.xml` (repo root) is a **symlink to `manifests/integration/wrynose.xml`**,
  so a bare `repo init` (no `-m`) resolves to the validated **wrynose (6.0 LTS)**
  build.
- `manifests/integration/scarthgap.xml` is the previous known-good **scarthgap
  (5.0 LTS)** baseline.

## Usage

```shell
# 1. Create an empty workspace and enter the build container
mkdir -p ~/yocto/workspace && cd ~/yocto/workspace
mkdir -p ~/yocto/sstate-cache/
mkdir -p ~/yocto/downloads/
mkdir -p ~/yocto/keys/
# 2a. Fetch sources — default is wrynose 6.0 (default.xml symlink):
repo init -u ssh://git@github.com/KorribanMaster/eicke-manifest -b main
# 2b. ...or the previous scarthgap 5.0 baseline:
repo init -u ssh://git@github.com/KorribanMaster/eicke-manifest \
          -b main -m manifests/integration/scarthgap.xml
repo sync
.repo/manifests/dock.sh            # build + enter the build container (cwd bind-mounted)
```

## Build the image

```shell
# inside the container
source integration-init-build-env  # sets TEMPLATECONF + runs oe-init-build-env, cd's into ./build-integration
bitbake eicke-image                # -> tmp/deploy/images/<machine>/eicke-image-*.wic
bitbake eicke-update-image         # -> the *.swu update artifact
```

## Layers

| Project | Source | Branch (wrynose) |
|---|---|---|
| bitbake | https://github.com/openembedded/bitbake | 2.18 |
| openembedded-core | https://github.com/openembedded/openembedded-core | wrynose |
| meta-yocto (meta-yocto-bsp) | https://git.yoctoproject.org/meta-yocto | wrynose |
| meta-openembedded | https://github.com/openembedded/meta-openembedded | wrynose |
| meta-swupdate | https://github.com/sbabic/meta-swupdate | wrynose |
| meta-secure-core (UEFI Secure Boot, TPM2, encrypted storage) | https://github.com/Wind-River/meta-secure-core | wrynose |
| [meta-eicke](https://github.com/KorribanMaster/meta-eicke) | https://github.com/KorribanMaster/meta-eicke | wrynose |

The scarthgap baseline (`manifests/integration/scarthgap.xml`) instead tracks
**poky**, **meta-openembedded** and **meta-swupdate** on `scarthgap`, with
`meta-eicke` on `scarthgap`.

### Targets

- `MACHINE = "qemux86-64"` (default) — boot/test with
  `runqemu eicke-image wic ovmf nographic` (run `dock.sh` with
  `EICKE_DOCKER_QEMU=1` for KVM + networking).
- `MACHINE = "genericx86-64"` — real 64-bit x86 hardware; flash the `.wic` with
  `bmaptool` / `dd`.

Edit `build-integration/conf/local.conf` to switch the machine.
