# framework

Personal atomic Fedora image built on top of [silverblue-main](https://github.com/ublue-os/main), with a full Hyprland compositor stack layered on.

## First-time setup

```bash
# Generate cosign keypair — store private key + password in GitHub secrets
cosign generate-key-pair

# Secrets needed in the repo:
#   COSIGN_PRIVATE_KEY   (contents of cosign.key)
#   COSIGN_PASSWORD      (the password you chose)
```

## Rebase from bluefin-dx

After the first image is published to ghcr.io:

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/nkbooth/framework:latest
```

## Repo layout

```
Containerfile               image definition
config/
  files/                    overlaid onto OS root at build time
    etc/yum.repos.d/        extra RPM repos (1Password, etc.)
    etc/pki/rpm-gpg/        GPG keys for those repos
    usr/share/ublue-os/     just recipes available system-wide
.github/workflows/build.yml build + sign + push on push/schedule
justfile                    local dev helpers (buildah, status)
```

## Adding packages

Layer order matters for cache efficiency — keep stable packages near the top and frequently-changing ones near the bottom.

```dockerfile
RUN rpm-ostree install <package> && ostree container commit
```

## Updating the base

The weekly cron in `build.yml` rebuilds against the latest `bluefin-dx:43` automatically.
To pin to a specific digest instead of `stable`, change the `ARG` in `Containerfile`.
