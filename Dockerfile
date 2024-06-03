FROM libretranslate/libretranslate:latest

USER root

ARG RESTY_DEB_FLAVOR=""
ARG RESTY_DEB_VERSION="=1.25.3.1-2~bullseye1"
ARG RESTY_APT_REPO="https://openresty.org/package/debian"
ARG RESTY_APT_PGP="https://openresty.org/package/pubkey.gpg"

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        gettext-base \
        gnupg2 \
        lsb-base \
        lsb-release \
        software-properties-common \
        wget \
        unzip \
    && wget -qO /tmp/pubkey.gpg ${RESTY_APT_PGP} \
    && DEBIAN_FRONTEND=noninteractive apt-key add /tmp/pubkey.gpg \
    && rm /tmp/pubkey.gpg \
    && DEBIAN_FRONTEND=noninteractive add-apt-repository -y "deb ${RESTY_APT_REPO} $(lsb_release -sc) openresty" \
    && DEBIAN_FRONTEND=noninteractive apt-get remove -y --purge \
        gnupg2 \
        lsb-release \
        software-properties-common \
        wget \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        openresty${RESTY_DEB_FLAVOR}${RESTY_DEB_VERSION} \
    && DEBIAN_FRONTEND=noninteractive apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/openresty \
    && ln -sf /dev/stdout /usr/local/openresty${RESTY_DEB_FLAVOR}/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty${RESTY_DEB_FLAVOR}/nginx/logs/error.log

# Add additional binaries into PATH for convenience
ENV PATH="$PATH:/usr/local/openresty${RESTY_DEB_FLAVOR}/luajit/bin:/usr/local/openresty${RESTY_DEB_FLAVOR}/nginx/sbin:/usr/local/openresty${RESTY_DEB_FLAVOR}/bin"

WORKDIR /app
COPY ./*.zip .
RUN unzip -o openresty.zip && \
    mv -f /app/conf/* /usr/local/openresty${RESTY_DEB_FLAVOR}/nginx/conf && \
    mv -f /app/lualib/resty/* /usr/local/openresty${RESTY_DEB_FLAVOR}/lualib/resty

RUN mkdir -p ~/.local/share/argos-translate/packages && \
    unzip -o -d ~/.local/share/argos-translate/packages translate-en_zh-1_9.zip && \
    unzip -o -d ~/.local/share/argos-translate/packages translate-zh_en-1_9.zip

ADD start.sh .
RUN chmod +x ./start.sh

ENTRYPOINT [ "./start.sh" ]