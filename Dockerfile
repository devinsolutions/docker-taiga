# Python 3.7 is currently not suppored. See https://github.com/taigaio/taiga-back/issues/1328.
FROM python:3.6-alpine3.10
RUN set -ex; \
    \
    apk add --no-cache \
        libjpeg-turbo \
        libpq \
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
    pip install --no-cache-dir 'uWSGI>=2.0,<2.1'; \
    addgroup -g 101 -S taiga; \
    adduser -D -H -g taiga -G taiga -s /sbin/nologin -S -u 101 taiga; \
    \
    find /usr/local -depth \
        \( \
            \( -type d -a \( -name test -o -name tests \) \) \
            -o \
            \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
        \) -exec rm -rf '{}' +; \
    apk del .build-deps; \
    rm -rf /var/cache/apk/*
# !!! DO NOT FORGET TO UPDATE "tags" FILE !!!
ENV TAIGA_VERSION=4.2.11 \
    TAIGA_BACK_SHA256SUM=dc04904e3264b4fa1282aa227015a890ca693ef4f2625e1a6c9979cc0c0ad08a \
    TAIGA_FRONT_SHA256SUM=b5c922409b300940e391f16b062ef9c5fbf3c2d938ad0a095072b3cc676089a6
RUN set -ex; \
    \
    apk add --no-cache --virtual .build-deps \
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
        https://github.com/taigaio/taiga-back/archive/${TAIGA_VERSION}.tar.gz; \
    echo "${TAIGA_BACK_SHA256SUM}  taiga-back.tar.gz" | sha256sum -c; \
    tar -xzf taiga-back.tar.gz; \
    rm -r taiga-back.tar.gz taiga-back-${TAIGA_VERSION}/tests; \
    mv taiga-back-${TAIGA_VERSION} /opt/taiga-back; \
    cd /opt/taiga-back; \
    # Django 1.11.20 is insecure
    sed -i '/^django==/ s/1\.11\.20$/1.11.22/' requirements.txt; \
    sed -i '/^gunicorn==/d' requirements.txt; \
    pip install --no-cache-dir -r requirements.txt; \
    ./manage.py compilemessages; \
    mkdir -p /etc/opt/taiga-back /srv/taiga-back/media /srv/taiga-back/static; \
    cd -; \
    \
    wget -q -O taiga-front-dist.tar.gz \
        https://github.com/taigaio/taiga-front-dist/archive/${TAIGA_VERSION}-stable.tar.gz; \
    echo "${TAIGA_FRONT_SHA256SUM}  taiga-front-dist.tar.gz" | sha256sum -c; \
    tar -xzf taiga-front-dist.tar.gz; \
    mv taiga-front-dist-${TAIGA_VERSION}-stable/dist /opt/taiga-front; \
    rm -r taiga-front-dist.tar.gz taiga-front-dist-${TAIGA_VERSION}-stable; \
    mkdir -p /etc/opt/taiga-front; \
    # Removes origin from "api" URL. By default, the API is served on port
    # 8080. Also, the URL doesn't have to be absolute, so this make the
    # default configuration more generic.
    sed -i 's|http://localhost:8000||' /opt/taiga-front/conf.example.json; \
    mv /opt/taiga-front/conf.example.json /etc/opt/taiga-front/conf.json; \
    ln -s /etc/opt/taiga-front/conf.json /opt/taiga-front/conf.json; \
    \
    find /opt/taiga-back /opt/taiga-front -type d -exec chmod 755 '{}' +; \
    find /opt/taiga-back /opt/taiga-front -type f -exec chmod 644 '{}' +; \
    chmod 755 /opt/taiga-back/manage.py; \
    \
    find /opt/taiga-back /usr/local -depth \
        \( \
            # taiga-back requires django.test and there's no other test directory
            \( -type d -a -name tests \) \
            -o \
            \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
        \) -exec rm -rf '{}' +; \
    apk del .build-deps; \
    rm -rf /var/cache/apk/*
COPY files /
WORKDIR /opt/taiga-back
ENV \
    # See https://uwsgi-docs.readthedocs.io/en/latest/HTTP.html.
    UWSGI_HTTP=:8080 \
    # See https://uwsgi-docs.readthedocs.io/en/latest/StaticFiles.html#offloading and
    # https://uwsgi-docs.readthedocs.io/en/latest/OffloadSubsystem.html.
    UWSGI_OFFLOAD_THREADS=1
ENTRYPOINT ["taiga-ctl"]
CMD ["migrate", "runserver"]
EXPOSE 8080
