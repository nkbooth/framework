IMAGE := "ghcr.io/nkbooth/framework"

default:
    @just --list

# Rebase to your custom image
rebase:
    rpm-ostree rebase ostree-image-signed:docker://{{ IMAGE }}:latest

# Rebase back to upstream silverblue-main
rebase-upstream:
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/silverblue-main:stable

# Build locally for testing (requires buildah)
build:
    buildah build -t framework:local .

# Show current and pending deployment
status:
    rpm-ostree status

# Generate a new cosign keypair (run once, store private key in secrets)
gen-keys:
    cosign generate-key-pair
