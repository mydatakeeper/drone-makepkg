FROM %FROM%

RUN set -xe \
    && pacman -Syu --noconfirm --needed sudo base-devel git openssh \
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
        ${checkdepends[@]}  $(eval "echo \${checkdepends_$(pacman-conf Architecture[@]}") \
        ${depends[@]}  $(eval "echo \${depends_$(pacman-conf Architecture)[@]}") \
    && if [ -n "$validpgpkeys" ]; then \
        pacman-key --recv-keys ${validpgpkeys[@]}; \
    fi \
    && chown alarm -R . \
    && export PLUGIN_KNOWN_HOST PLUGIN_DEPLOYMENT_KEY DRONE_COMMIT_AUTHOR_EMAIL DRONE_COMMIT_AUTHOR_NAME \
    && sudo --preserve-env=PLUGIN_KNOWN_HOST,PLUGIN_DEPLOYMENT_KEY,DRONE_COMMIT_AUTHOR_EMAIL,DRONE_COMMIT_AUTHOR_NAME -u alarm bash -c '\
        mkdir ~/.ssh -p \
        && printf %s "$PLUGIN_KNOWN_HOST" > ~/.ssh/known_hosts \
        && printf %s "$PLUGIN_DEPLOYMENT_KEY" > ~/.ssh/id_rsa \
        && eval `ssh-agent -s` \
        && if [ -s ~/.ssh/id_rsa ]; then \
            chmod 600 ~/.ssh/id_rsa && ssh-add ~/.ssh/id_rsa; \
        fi \
        && git config --global user.email "$DRONE_COMMIT_AUTHOR_EMAIL" \
        && git config --global user.name "$DRONE_COMMIT_AUTHOR_NAME" \
        && aarch64-makepkg --noconfirm --nosign --nodeps \
    '
