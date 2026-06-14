ARG BASE_IMAGE="ghcr.io/ublue-os/silverblue-main"
ARG FEDORA_MAJOR_VERSION="44"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}

# ── Repos ─────────────────────────────────────────────────────────────────────
COPY config/files/etc/yum.repos.d/ /etc/yum.repos.d/

# sdegler/hyprland — hyprland, eww-git, hyprpaper, swaylock-effects, waypaper, etc.
# atim/starship + atim/gping — not in standard Fedora repos
RUN source /etc/os-release && \
    curl -fsSL -o /etc/yum.repos.d/sdegler-hyprland.repo \
      "https://copr.fedorainfracloud.org/coprs/sdegler/hyprland/repo/fedora-${VERSION_ID}/sdegler-hyprland-fedora-${VERSION_ID}.repo" && \
    curl -fsSL -o /etc/yum.repos.d/atim-starship.repo \
      "https://copr.fedorainfracloud.org/coprs/atim/starship/repo/fedora-${VERSION_ID}/atim-starship-fedora-${VERSION_ID}.repo" && \
    curl -fsSL -o /etc/yum.repos.d/atim-gping.repo \
      "https://copr.fedorainfracloud.org/coprs/atim/gping/repo/fedora-${VERSION_ID}/atim-gping-fedora-${VERSION_ID}.repo" && \
    curl -fsSL -o /etc/yum.repos.d/tailscale.repo \
      "https://pkgs.tailscale.com/stable/fedora/tailscale.repo" \
    && ostree container commit

# ── Hyprland compositor stack ─────────────────────────────────────────────────
# Podman + Buildah ship with silverblue-main; podman-docker adds the docker shim. Add the Hyprland desktop layer
# --setopt=install_weak_deps=False drops recommended-but-not-required packages
# (kitty, nwg-panel, wofi, etc.) that hyprland and waybar suggest but we don't use.
# hyprpwcenter is dropped entirely — its COPR package incorrectly lists build-time
# deps (cmake, gcc-c++) as runtime requirements, pulling in the full compiler toolchain.
RUN echo 'install_weak_deps=False' >> /etc/dnf/dnf.conf

# Sync base image packages with current repos before layering; rpm-ostree in
# container build mode cannot upgrade @System packages, but dnf can.
RUN dnf upgrade -y && dnf clean all && ostree container commit

RUN rpm-ostree install \
    cava \
    dunst \
    eww-git \
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
# gcc + binutils needed for nvim-treesitter to compile parsers at runtime
RUN rpm-ostree install \
    binutils \
    gcc \
    just \
    podman-docker \
    task \
    && ostree container commit

# ── User CLI tools ────────────────────────────────────────────────────────────
RUN rpm-ostree install \
    aerc \
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

# atuin Fedora package omits daemon feature; install official musl binary
RUN curl -fsSL "https://github.com/atuinsh/atuin/releases/latest/download/atuin-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /tmp && \
    install -m 755 /tmp/atuin-x86_64-unknown-linux-musl/atuin /usr/bin/atuin && \
    rm -rf /tmp/atuin-x86_64-unknown-linux-musl && \
    ostree container commit

# eza has no Fedora 43 RPM; install musl binary from GitHub releases
RUN curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /tmp && \
    install -m 755 /tmp/eza /usr/bin/eza && \
    rm /tmp/eza && \
    ostree container commit

# zellij has no Fedora 43 RPM; install static musl binary from GitHub releases
RUN curl -fsSL "https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /tmp && \
    install -m 755 /tmp/zellij /usr/bin/zellij && \
    rm /tmp/zellij && \
    ostree container commit

# neovim — install latest release tarball from GitHub (newer than Fedora RPM)
RUN curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" \
    | tar -xz -C /tmp && \
    cp -r /tmp/nvim-linux-x86_64/* /usr/ && \
    rm -rf /tmp/nvim-linux-x86_64 && \
    ostree container commit

# SubTUI — music player TUI; installed from GitHub RPM release
RUN SUBTUI_VERSION=$(curl -fsSL https://api.github.com/repos/MattiaPun/SubTUI/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v') && \
    rpm-ostree install \
      "https://github.com/MattiaPun/SubTUI/releases/download/v${SUBTUI_VERSION}/SubTUI_${SUBTUI_VERSION}_linux_amd64.rpm" \
    && ostree container commit

# ── Fonts ─────────────────────────────────────────────────────────────────────
RUN rpm-ostree install \
    adwaita-fonts-all \
    liberation-fonts-all \
    opendyslexic-fonts \
    && ostree container commit

# JetBrains Mono NF + Cascadia Code NF from nerd-fonts releases (NF builds are
# supersets of the upstream fonts, so we skip the plain RPM packages)
RUN mkdir -p /usr/share/fonts/nerd-fonts && \
    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" \
      | tar -xJ -C /usr/share/fonts/nerd-fonts && \
    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.tar.xz" \
      | tar -xJ -C /usr/share/fonts/nerd-fonts && \
    fc-cache -f && \
    ostree container commit

# ── Tailscale ─────────────────────────────────────────────────────────────────
RUN rpm-ostree install tailscale \
    && ostree container commit

# ── 1Password desktop ─────────────────────────────────────────────────────────
# Repo created inline and deleted post-install (repos don't work at ostree runtime).
# dnf5 bypasses rpm-ostree's bwrap which blocks chrome-sandbox setuid in CI.
# optfix: /opt is read-only at ostree runtime; files live in /var/opt with a
# symlink from /opt so they persist across deployments in the mutable /var layer.
# Both desktop app and CLI (op) installed together from the official repo.
RUN rpm --import https://downloads.1password.com/linux/keys/1password.asc && \
    printf '[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://downloads.1password.com/linux/keys/1password.asc\n' \
      > /etc/yum.repos.d/1password.repo && \
    dnf5 install -y 1password 1password-cli && \
    rm -f /etc/yum.repos.d/1password.repo && \
    mkdir -p /var/opt && \
    mv /opt/1Password /var/opt/1Password && \
    ln -sf /var/opt/1Password /opt/1Password && \
    ostree container commit

# ── Virtualization ────────────────────────────────────────────────────────────
# libvirt-daemon-driver-qemu provides virtqemud (modular daemon replaces libvirtd)
# libvirt-daemon-config-network provides the default NAT network
# qemu-kvm-core is the minimal KVM-enabled QEMU binary
RUN rpm-ostree install \
    libvirt-daemon-config-network \
    libvirt-daemon-driver-qemu \
    qemu-kvm \
    && ostree container commit

# ── Overlay files ─────────────────────────────────────────────────────────────
COPY config/files/etc/ /etc/
COPY config/files/usr/ /usr/

RUN ostree container commit
