FROM mydatakeeper/archlinuxarm:%CARCH%

RUN set -xe \
    && pacman -Syu --noconfirm --needed sudo base-devel git \
    && pacman -Scc --noconfirm \
    && echo "alarm ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ENV PLUGIN_KEYS ''
ENV PLUGIN_REPOS ''
CMD set -xe \
    && for key in $(echo $PLUGIN_KEYS | tr ',' ' '); do \
        pacman-key --recv-keys "$key" \
        && pacman-key --lsign-key "$key"; \
    done \
    && for repo in $(echo $PLUGIN_REPOS | tr ',' ' '); do \
        echo -e "$repo" >> '/etc/pacman.conf'; \
    done \
    && source PKGBUILD \
    && pacman -Syu --noconfirm ${makedepends[@]} ${checkdepends[@]} ${depends[@]} --needed \
    && pacman-key --recv-keys ${validpgpkeys[@]} \
    && chown alarm -R . \
    && sudo -u alarm makepkg --noconfirm
