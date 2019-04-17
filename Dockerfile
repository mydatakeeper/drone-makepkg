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
    && pacman -Syu --noconfirm \
    && pacman-db-upgrade \
    && pacman -Scc --noconfirm \
    && chown alarm -R . \
    && sudo -u alarm makepkg --noconfirm -s
