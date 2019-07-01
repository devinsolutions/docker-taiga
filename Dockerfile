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
ENV TAIGA_VERSION=4.2.7 \
    TAIGA_BACK_SHA256SUM=a25f4c880fceb6552c0ffd027ec5345a54a13b2a1379e586efd1d6de3bbf42a6 \
    TAIGA_FRONT_SHA256SUM=b0f94806455b811848b3e10df8d3f63a0a741da83296d267fe83b19767597ee7
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
    chmod -R go-w /opt/taiga-back /opt/taiga-front; \
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
ENV TAIGA_GOOGLE_AUTH_VERSION=d9933cc387d9402de1250d8280152eccebd0bf4d \
    TAIGA_GOOGLE_AUTH_SHA256SUM=4983a5517b13da033bb9abf5b26ed6ef2c68abdc51d5cf3645e1dad830d63278
RUN set -ex; \
    \
    apk add --no-cache --virtual .build-deps \
        jq \
    ; \
    \
    wget -q -O taiga-contrib-google-auth.tar.gz \
        https://github.com/Nox-404/taiga-contrib-google-auth/archive/${TAIGA_GOOGLE_AUTH_VERSION}.tar.gz; \
    echo "${TAIGA_GOOGLE_AUTH_SHA256SUM}  taiga-contrib-google-auth.tar.gz" | sha256sum -c; \
    tar -xzf taiga-contrib-google-auth.tar.gz; \
    rm taiga-contrib-google-auth.tar.gz; \
    cd taiga-contrib-google-auth-${TAIGA_GOOGLE_AUTH_VERSION}; \
    pip install --no-cache-dir ./back; \
    mkdir /opt/taiga-front/plugins; \
    cp -rL front/dist /opt/taiga-front/plugins/google-auth; \
    cd ..; \
    rm -r taiga-contrib-google-auth-${TAIGA_GOOGLE_AUTH_VERSION}; \
    jq '.contribPlugins += ["/plugins/google-auth/google-auth.json"] | .googleClientId = null' \
        /etc/opt/taiga-front/conf.json > conf.json; \
    mv conf.json /etc/opt/taiga-front/conf.json; \
    \
    find /usr/local -depth \
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
