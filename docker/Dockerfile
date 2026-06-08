# Yocto build container for the meta-eicke project.
#
# Built on the official CROPS/poky image, which ships every Yocto host
# dependency for Ubuntu 22.04 and — via its entrypoint (distro-entry.sh) —
# transparently maps the UID/GID of the bind-mounted workdir owner, so files
# created in the build stay owned by the host user. We only add Google's
# `repo` tool, which CROPS does not bundle.
# (crops/poky's newest Ubuntu tag is ubuntu-22.04; 22.04 is a supported
# scarthgap build host.)
FROM crops/poky:ubuntu-22.04

USER root
RUN wget -q https://storage.googleapis.com/git-repo-downloads/repo \
        -O /usr/local/bin/repo \
    && chmod a+x /usr/local/bin/repo

# IMPORTANT: do not override the CROPS ENTRYPOINT/CMD — it performs the
# user-mapping setup. Invoke the container with `--workdir=/workdir`.
