FROM %FROM%

RUN set -xe \
    && pacman -Syu --noconfirm --needed sudo base-devel git \
    && pacman -Scc --noconfirm

CMD trap 'rm -rf ~/.ssh' HUP INT QUIT ABRT KILL ALRM TERM \
    && mkdir ~/.ssh -p \
    && eval `ssh-agent -s` \
    && cat > ~/.ssh/known_hosts <<< "$PLUGIN_KNOWN_HOST" \
    && if [ -n "$PLUGIN_DEPLOYMENT_KEY" ]; then \
        cat > ~/.ssh/id_rsa <<<  "$PLUGIN_DEPLOYMENT_KEY" \
        && chmod 600 ~/.ssh/id_rsa \
        && ssh-add ~/.ssh/id_rsa; \
    fi \
    && set -xe \
    && for key in $(echo $PLUGIN_KEYS | tr ',' ' '); do \
        pacman-key --recv-keys "$key" \
        && pacman-key --lsign-key "$key"; \
    done \
    && for repo in $(echo $PLUGIN_REPOS | tr ',' ' '); do \
        echo -e "$repo" >> '/etc/pacman.conf'; \
    done \
    && source ./PKGBUILD \
    && pacman -Syu --noconfirm --needed \
        ${makedepends[@]} $(eval "echo \${makedepends_$(uname -m)[@]}") \
        ${checkdepends[@]}  $(eval "echo \${checkdepends_$(uname -m)[@]}") \
        ${depends[@]}  $(eval "echo \${depends_$(uname -m)[@]}") \
    && if [ -n "$validpgpkeys" ]; then \
        pacman-key --recv-keys ${validpgpkeys[@]}; \
    fi \
    && chown alarm -R . \
    && sudo -u alarm git config --global user.email ${DRONE_COMMIT_AUTHOR_EMAIL} \
    && sudo -u alarm git config --global user.name ${DRONE_COMMIT_AUTHOR_NAME} \
    && sudo -u alarm makepkg --noconfirm --nosign
