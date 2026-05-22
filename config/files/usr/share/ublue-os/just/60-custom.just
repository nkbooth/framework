# Custom just recipes — available system-wide via `just` on this image

# Rebase to the custom framework image
[group('framework')]
rebase-framework:
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/nkbooth/framework:latest

# Rebase to upstream silverblue-main
[group('framework')]
rebase-upstream:
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/silverblue-main:stable

# Add current user to the libvirt group (required for qemu:///system access)
[group('framework')]
setup-libvirt:
    sudo usermod -aG libvirt {{ env("USER") }}
    @echo "Log out and back in for group membership to take effect"
