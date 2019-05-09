FROM %FROM%

RUN set -xe \
    && pacman -Syu --noconfirm --needed sudo base-devel git openssh gnupg \
    && pacman -Scc --noconfirm

SHELL ["/bin/bash", "-c"]
CMD set -xe \
    && source PKGBUILD \
    && for key in $(echo $PLUGIN_KEYS | tr ',' ' '); do \
        pacman-key --recv-keys "$key" \
        && pacman-key --lsign-key "$key"; \
    done \
    && echo >> '/etc/pacman.conf' \
    && for repo in $(echo $PLUGIN_REPOS | tr ',' ' '); do \
        echo -e "$repo" >> '/etc/pacman.conf'; \
    done \
    && pacman -Syu --noconfirm --needed \
        ${makedepends[@]} $(eval "echo \${makedepends_$(pacman-conf Architecture)[@]}") \
        ${checkdepends[@]}  $(eval "echo \${checkdepends_$(pacman-conf Architecture)[@]}") \
        ${depends[@]}  $(eval "echo \${depends_$(pacman-conf Architecture)[@]}") \
    && chown alarm -R . \
    && export PLUGIN_KNOWN_HOST PLUGIN_DEPLOYMENT_KEY DRONE_COMMIT_AUTHOR_EMAIL DRONE_COMMIT_AUTHOR_NAME validpgpkeys \
    && sudo --preserve-env=PLUGIN_KNOWN_HOST,PLUGIN_DEPLOYMENT_KEY,DRONE_COMMIT_AUTHOR_EMAIL,DRONE_COMMIT_AUTHOR_NAME,validpgpkeys -u alarm bash -c '\
        mkdir ~/.ssh -p \
        && eval `ssh-agent -s` \
        && cat > ~/.ssh/known_hosts <<< "$PLUGIN_KNOWN_HOST" \
        && if [ -n "$PLUGIN_DEPLOYMENT_KEY" ]; then \
            cat > ~/.ssh/id_rsa <<<  "$PLUGIN_DEPLOYMENT_KEY" \
            && chmod 600 ~/.ssh/id_rsa \
            && ssh-add ~/.ssh/id_rsa; \
        fi \
        && git config --global user.email "$DRONE_COMMIT_AUTHOR_EMAIL" \
        && git config --global user.name "$DRONE_COMMIT_AUTHOR_NAME" \
        && if [ -n "$validpgpkeys" ]; then \
            gpg --recv-keys ${validpgpkeys[@]}; \
        fi \
        && makepkg --noconfirm --nosign --nodeps \
    '
