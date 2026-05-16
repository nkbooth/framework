# Custom just recipes — available system-wide via `just` on this image

# Rebase to the custom framework image
[group('framework')]
rebase-framework:
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/nkbooth/framework:latest

# Rebase to upstream bluefin-dx
[group('framework')]
rebase-upstream:
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bluefin-dx:stable
