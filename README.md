# framework

Personal atomic Fedora image built on top of [silverblue-main](https://github.com/ublue-os/main), with a full Hyprland compositor stack layered on.

## Signing key

CI signs every image with the cosign key whose public half is `cosign.pub`. The
key pair and its password live in 1Password, not on disk:

- `op://Developer/cosign nkbooth-framework/password`
- `op://Developer/cosign nkbooth-framework/cosign/key` (private, encrypted)
- `op://Developer/cosign nkbooth-framework/cosign/pub`

GitHub secrets `COSIGN_PRIVATE_KEY` and `COSIGN_PASSWORD` are set from that item:

```bash
op read "op://Developer/cosign nkbooth-framework/cosign/key" | gh secret set COSIGN_PRIVATE_KEY -R nkbooth/framework
op read "op://Developer/cosign nkbooth-framework/password" | gh secret set COSIGN_PASSWORD -R nkbooth/framework
```

The image ships `cosign.pub` as `/etc/pki/containers/nkbooth-framework.pub` and a
`sigstoreSigned` entry for `ghcr.io/nkbooth/framework` in
`/etc/containers/policy.json`, so the host refuses an unsigned or wrongly-signed
image. Rotating the key therefore takes two builds: first ship an image whose
policy trusts both keys (`keyPaths`), then switch CI to the new key.

### If the key is lost

The host can no longer pull its own image. Generate a new pair, update the
1Password item, the GitHub secrets and `cosign.pub`, push, then rebase once with
a local policy that accepts the new key:

```bash
sudo cp new-cosign.pub /etc/pki/containers/nkbooth-framework.pub
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/nkbooth/framework:latest
```

`/etc/pki/containers/nkbooth-framework.pub` is then locally modified; once the
new image is booted, `sudo cp /usr/etc/pki/containers/nkbooth-framework.pub
/etc/pki/containers/` puts it back under image control. If `/etc` is unusable,
`sudo rpm-ostree rebase` with a temporary `/etc/containers/policy.json` whose
`ghcr.io/nkbooth/framework` entry is `insecureAcceptAnything` works the same way;
restore the file from `/usr/etc/containers/policy.json` afterwards.

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
    etc/pki/containers/     cosign public key the host verifies images against
    etc/containers/         registries.d entry for sigstore attachments
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
