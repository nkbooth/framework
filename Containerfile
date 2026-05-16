ARG BASE_IMAGE="ghcr.io/ublue-os/bluefin-dx"
ARG FEDORA_MAJOR_VERSION="43"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}

# ── Repos ─────────────────────────────────────────────────────────────────────
COPY config/files/etc/yum.repos.d/ /etc/yum.repos.d/
COPY config/files/etc/pki/rpm-gpg/ /etc/pki/rpm-gpg/

# ── Hyprland compositor stack ─────────────────────────────────────────────────
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
    zellij \
    task \
    && ostree container commit

# ── 1Password CLI ─────────────────────────────────────────────────────────────
RUN rpm-ostree install 1password-cli \
    && ostree container commit

# ── Overlay files (configs, just recipes, systemd units) ──────────────────────
COPY config/files/usr/ /usr/

RUN ostree container commit
