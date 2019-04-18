FROM mydatakeeper/archlinuxarm:%CARCH%

RUN set -xe \
    && pacman -Syu --noconfirm --needed sudo base-devel git \
    && pacman -Scc --noconfirm

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
    && pacman -Syu --noconfirm --needed \
        ${makedepends[@]} $(eval "echo \${makedepends_$(uname -m)[@]}") \
        ${checkdepends[@]}  $(eval "echo \${checkdepends_$(uname -m)[@]}") \
        ${depends[@]}  $(eval "echo \${depends_$(uname -m)[@]}") \
    && if [ -n "$validpgpkeys" ]; then \
        pacman-key --recv-keys ${validpgpkeys[@]}; \
    fi \
    && chown alarm -R . \
    && sudo -u alarm makepkg --noconfirm --nosign
