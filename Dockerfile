FROM python:3.7-alpine3.12
RUN set -ex; \
    \
    export CFLAGS="-Os"; \
    export CPPFLAGS="${CFLAGS}"; \
    export LDFLAGS="-Wl,--strip-all"; \
    export PYTHONDONTWRITEBYTECODE=yes; \
    \
    apk add --no-cache \
        libjpeg-turbo \
        libpq\>=12.2-r0 \
        libxslt \
        mailcap \
        pcre \
    ; \
    \
    apk add --no-cache --virtual .build-deps \
        gcc \
        linux-headers \
        musl-dev \
        pcre-dev \
    ; \
    \
    pip install --no-cache-dir --no-compile 'uWSGI>=2.0,<2.1'; \
    \
    addgroup -g 101 -S taiga; \
    adduser -D -H -g taiga -G taiga -s /sbin/nologin -S -u 101 taiga; \
    \
    mkdir -p \
        /etc/opt/taiga-back \
        /etc/opt/taiga-front \
        /srv/taiga-back/media \
        /srv/taiga-back/static \
    ; \
    chown taiga:taiga \
        /srv/taiga-back/media \
        /srv/taiga-back/static \
    ; \
    \
    apk del .build-deps; \
    rm -rf /root/.cache /var/cache/apk/*
# !!! DO NOT FORGET TO UPDATE "tags" FILE !!!
ENV TAIGA_BACK_VERSION=5.0.15 \
    TAIGA_BACK_SHA256SUM=e9ed85b929d921fd856c993ce2034a3e2b6d6d7554b31acc952036664c55d532
RUN set -ex; \
    \
    export CFLAGS="-Os"; \
    export CPPFLAGS="${CFLAGS}"; \
    export LDFLAGS="-Wl,--strip-all"; \
    export PYTHONDONTWRITEBYTECODE=yes; \
    \
    apk add --no-cache --virtual .build-deps \
        g++ \
        gcc \
        gettext \
        libffi-dev \
        libjpeg-turbo-dev \
        libxslt-dev \
        musl-dev \
        postgresql-dev \
        zlib-dev \
    ; \
    \
    wget -q -O taiga-back.tar.gz \
        https://github.com/taigaio/taiga-back/archive/${TAIGA_BACK_VERSION}.tar.gz; \
    echo "${TAIGA_BACK_SHA256SUM}  taiga-back.tar.gz" | sha256sum -c; \
    tar -xzf taiga-back.tar.gz; \
    rm -r taiga-back.tar.gz; \
    mv taiga-back-${TAIGA_BACK_VERSION} /opt/taiga-back; \
    \
    cd /opt/taiga-back; \
    \
    sed -i '/^gunicorn==/d' requirements.txt; \
    pip install --no-cache-dir --no-compile -r requirements.txt; \
    find /usr/local -depth -type d -name tests -exec rm -rf '{}' +; \
    \
    ./manage.py compilemessages; \
    \
    find . -mindepth 1 \( \
            -name '*.po' -o ! \( \
                -path ./LICENSE \
                -o \
                -path ./manage.py \
                -o \
                -path ./NOTICE \
                -o \
                -path ./settings \
                -o \
                -path ./settings/'*' \
                -o \
                -path ./taiga \
                -o \
                -path ./taiga/'*' \
            \) \
        \) -exec rm -rf '{}' +; \
    \
    find . \( -type d -o -type f -path ./manage.py \) -exec chmod 755 '{}' +; \
    find . -type f ! -path ./manage.py -exec chmod 644 '{}' +; \
    \
    apk del .build-deps; \
    rm -rf /root/.cache /var/cache/apk/*
# !!! DO NOT FORGET TO UPDATE "tags" FILE !!!
ENV TAIGA_FRONT_VERSION=5.0.14 \
    TAIGA_FRONT_SHA256SUM=87cae2b9fa82d97c86895e5f0078efcad74918c4b8e7936e8473ac83e2a5c2d7
RUN set -ex; \
    \
    wget -q -O taiga-front-dist.tar.gz \
        https://github.com/taigaio/taiga-front-dist/archive/${TAIGA_FRONT_VERSION}-stable.tar.gz; \
    echo "${TAIGA_FRONT_SHA256SUM}  taiga-front-dist.tar.gz" | sha256sum -c; \
    tar -xzf taiga-front-dist.tar.gz; \
    mv taiga-front-dist-${TAIGA_FRONT_VERSION}-stable/dist /opt/taiga-front; \
    rm -r taiga-front-dist.tar.gz taiga-front-dist-${TAIGA_FRONT_VERSION}-stable; \
    \
    cd /opt/taiga-front; \
    \
    # Removes origin from "api" URL. By default, the API is served on port
    # 8080. Also, the URL doesn't have to be absolute, so this make the
    # default configuration more generic.
    sed -i 's|http://localhost:8000||' conf.example.json; \
    mv conf.example.json /etc/opt/taiga-front/conf.json; \
    ln -s /etc/opt/taiga-front/conf.json conf.json; \
    \
    find . -type d -exec chmod 755 '{}' +; \
    find . -type f -exec chmod 644 '{}' +
COPY root /
WORKDIR /opt/taiga-back
ENV \
    # See https://uwsgi-docs.readthedocs.io/en/latest/HTTP.html.
    UWSGI_HTTP=:8080 \
    # See https://uwsgi-docs.readthedocs.io/en/latest/StaticFiles.html#offloading and
    # https://uwsgi-docs.readthedocs.io/en/latest/OffloadSubsystem.html.
    UWSGI_OFFLOAD_THREADS=1
USER taiga
ENTRYPOINT ["taiga-ctl"]
CMD ["migrate", "run-server"]
EXPOSE 8080
