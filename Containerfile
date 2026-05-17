ARG BASE_IMAGE="ghcr.io/ublue-os/silverblue-main"
ARG FEDORA_MAJOR_VERSION="43"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}

# ── Repos ─────────────────────────────────────────────────────────────────────
COPY config/files/etc/yum.repos.d/ /etc/yum.repos.d/

# solopasha/hyprland — hyprland, hyprpaper, swaylock-effects, waypaper, etc.
# atim/starship + atim/gping — not in standard Fedora repos
RUN source /etc/os-release && \
    curl -fsSL -o /etc/yum.repos.d/solopasha-hyprland.repo \
      "https://copr.fedorainfracloud.org/coprs/solopasha/hyprland/repo/fedora-${VERSION_ID}/solopasha-hyprland-fedora-${VERSION_ID}.repo" && \
    curl -fsSL -o /etc/yum.repos.d/atim-starship.repo \
      "https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-${VERSION_ID}/atim-starship-fedora-${VERSION_ID}.repo" && \
    curl -fsSL -o /etc/yum.repos.d/atim-gping.repo \
      "https://copr.fedorainfracloud.org/coprs/atim/gping/repo/fedora-${VERSION_ID}/atim-gping-fedora-${VERSION_ID}.repo" \
    && ostree container commit

# ── Hyprland compositor stack ─────────────────────────────────────────────────
# Podman + Buildah ship with silverblue-main; add the Hyprland desktop layer
# --setopt=install_weak_deps=False drops recommended-but-not-required packages
# (kitty, nwg-panel, wofi, etc.) that hyprland and waybar suggest but we don't use.
# hyprpwcenter is dropped entirely — its COPR package incorrectly lists build-time
# deps (cmake, gcc-c++) as runtime requirements, pulling in the full compiler toolchain.
RUN echo 'install_weak_deps=False' >> /etc/dnf/dnf.conf

RUN rpm-ostree install \
    cava \
    dunst \
    hyprland \
    hyprland-contrib \
    hyprpaper \
    pyprland \
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

# ── User CLI tools ────────────────────────────────────────────────────────────
RUN rpm-ostree install \
    atuin \
    bat \
    btop \
    direnv \
    fd-find \
    gh \
    git-delta \
    glab \
    gping \
    ShellCheck \
    starship \
    zoxide \
    && ostree container commit

# eza has no Fedora 43 RPM; install musl binary from GitHub releases
RUN EZA_VERSION=$(curl -fsSL https://api.github.com/repos/eza-community/eza/releases/latest | grep '"tag_name"' | cut -d'"' -f4) && \
    curl -fsSL "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /tmp && \
    install -m 755 /tmp/eza /usr/bin/eza && \
    rm /tmp/eza && \
    ostree container commit

# zellij has no Fedora 43 RPM; install static musl binary from GitHub releases
RUN ZELLIJ_VERSION=$(curl -fsSL https://api.github.com/repos/zellij-org/zellij/releases/latest | grep '"tag_name"' | cut -d'"' -f4) && \
    curl -fsSL "https://github.com/zellij-org/zellij/releases/download/${ZELLIJ_VERSION}/zellij-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /tmp && \
    install -m 755 /tmp/zellij /usr/bin/zellij && \
    rm /tmp/zellij && \
    ostree container commit

# SubTUI — music player TUI; installed from GitHub RPM release
RUN SUBTUI_VERSION=$(curl -fsSL https://api.github.com/repos/MattiaPun/SubTUI/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v') && \
    rpm-ostree install \
      "https://github.com/MattiaPun/SubTUI/releases/download/v${SUBTUI_VERSION}/SubTUI_${SUBTUI_VERSION}_linux_amd64.rpm" \
    && ostree container commit

# ── 1Password CLI ─────────────────────────────────────────────────────────────
RUN rpm-ostree install 1password-cli \
    && ostree container commit

# ── Overlay files ─────────────────────────────────────────────────────────────
COPY config/files/usr/ /usr/

RUN ostree container commit
