# eicke-manifest

A [`repo`](https://gerrit.googlesource.com/git-repo/) manifest that assembles a
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

## Layers

| Project | Source | Branch |
|---|---|---|
| bitbake | https://github.com/openembedded/bitbake | 2.18 |
| openembedded-core | https://github.com/openembedded/openembedded-core | wrynose |
| meta-yocto (meta-yocto-bsp) | https://git.yoctoproject.org/meta-yocto | wrynose |
| meta-openembedded | https://github.com/openembedded/meta-openembedded | wrynose |
| meta-swupdate | https://github.com/sbabic/meta-swupdate | wrynose |
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
