ARG BASE_IMAGE="ghcr.io/ublue-os/silverblue-main"
ARG FEDORA_MAJOR_VERSION="43"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}

# ── Repos ─────────────────────────────────────────────────────────────────────
COPY config/files/etc/yum.repos.d/ /etc/yum.repos.d/

# solopasha/hyprland COPR — hyprland, hyprpaper, swaylock-effects, waypaper, etc.
RUN source /etc/os-release && \
    curl -fsSL -o /etc/yum.repos.d/solopasha-hyprland.repo \
      "https://copr.fedorainfracloud.org/coprs/solopasha/hyprland/repo/fedora-${VERSION_ID}/solopasha-hyprland-fedora-${VERSION_ID}.repo" \
    && ostree container commit

# ── Hyprland compositor stack ─────────────────────────────────────────────────
# Podman + Buildah ship with silverblue-main; add the Hyprland desktop layer
RUN rpm-ostree install \
    cava \
    dunst \
    hyprland \
    hyprland-contrib \
    hyprpaper \
    hyprpwcenter \
    pyprland \
    qt5-qtbase-devel \
    rofi \
    rofi-wayland \
    rofi-themes \
    swappy \
    swaylock-effects \
    waybar \
    waypaper \
    && ostree container commit

# ── CLI tooling ───────────────────────────────────────────────────────────────
RUN rpm-ostree install \
    just \
    task \
    && ostree container commit

# zellij has no Fedora 43 RPM; install static musl binary from GitHub releases
RUN ZELLIJ_VERSION=$(curl -fsSL https://api.github.com/repos/zellij-org/zellij/releases/latest | grep '"tag_name"' | cut -d'"' -f4) && \
    curl -fsSL "https://github.com/zellij-org/zellij/releases/download/${ZELLIJ_VERSION}/zellij-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /tmp && \
    install -m 755 /tmp/zellij /usr/bin/zellij && \
    rm /tmp/zellij && \
    ostree container commit

# ── 1Password CLI ─────────────────────────────────────────────────────────────
RUN rpm-ostree install 1password-cli \
    && ostree container commit

# ── Overlay files ─────────────────────────────────────────────────────────────
COPY config/files/usr/ /usr/

RUN ostree container commit
