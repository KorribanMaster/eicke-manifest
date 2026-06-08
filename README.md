# eicke-manifest

A [`repo`](https://gerrit.googlesource.com/git-repo/) manifest that assembles a
reproducible Yocto build for a basic **poky (scarthgap / 5.0 LTS)** x86-64 image
with:

- **GRUB-EFI** bootloader
- a custom **WIC image with an A/B (dual-copy) rootfs layout**
- **SWUpdate** for image updates (local `.swu`, applied via CLI / USB / web UI)

The build runs **inside a Docker container** (based on the official
[`crops/poky`](https://hub.docker.com/r/crops/poky) image) because the layer is
intended to be built from hosts that Yocto does not officially support (e.g.
Arch Linux). The host only needs **Docker** and **git**.

## Layers

| Project | Source | Branch |
|---|---|---|
| poky | https://git.yoctoproject.org/poky | scarthgap |
| meta-openembedded | https://github.com/openembedded/meta-openembedded | scarthgap |
| meta-swupdate | https://github.com/sbabic/meta-swupdate | scarthgap |
| [meta-eicke](https://github.com/KorribanMaster/meta-eicke) | this project | main |

## Quick start

```sh
# 1. Get the manifest (for the Docker env + repo URL). Repos are private, so
#    these use SSH (the container/host must have an SSH key with GitHub access).
git clone git@github.com:KorribanMaster/eicke-manifest.git

# 2. Create an empty workspace and enter the build container
mkdir -p yocto-workspace && cd yocto-workspace
../eicke-manifest/dock.sh

# --- inside the container (cwd = /workdir) ---
# 3. Fetch all sources
repo init -u ssh://git@github.com/KorribanMaster/eicke-manifest -b main -m default.xml
repo sync

# 4. Set up the build environment (uses meta-eicke's TEMPLATECONF)
. ./setup-environment            # creates ./build and cd's into it

# 5. Build
bitbake eicke-image              # -> tmp/deploy/images/<machine>/eicke-image-*.wic
bitbake eicke-update-image       # -> the *.swu update artifact
```

### Targets

- `MACHINE = "qemux86-64"` (default) — boot/test with
  `runqemu eicke-image wic ovmf nographic` (run `dock.sh` with
  `EICKE_DOCKER_QEMU=1` for KVM + networking).
- `MACHINE = "genericx86-64"` — real 64-bit x86 hardware; flash the `.wic` with
  `bmaptool` / `dd`.

Edit `build/conf/local.conf` to switch the machine.
