FROM python:3.7-alpine3.10
RUN set -ex; \
    \
    export PYTHONDONTWRITEBYTECODE=yes; \
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
    \
    apk del .build-deps; \
    rm -rf /var/cache/apk/*
# !!! DO NOT FORGET TO UPDATE "tags" FILE !!!
ENV TAIGA_BACK_VERSION=5.0.2 \
    TAIGA_BACK_SHA256SUM=3524a64fe312886482dc16ab21595b86d7113d90fcbc05decded41734cc62fde
RUN set -ex; \
    \
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
    find . -type d -exec chmod 755 '{}' +; \
    find . -type f ! -path ./manage.py -exec chmod 644 '{}' +; \
    \
    apk del .build-deps; \
    rm -rf /var/cache/apk/*
# !!! DO NOT FORGET TO UPDATE "tags" FILE !!!
ENV TAIGA_FRONT_VERSION=5.0.2 \
    TAIGA_FRONT_SHA256SUM=144661607e0af976ed75291633882161525db32a79cbc8c6dc0f2003329cf98f
RUN set -ex; \
    \
    wget -q -O taiga-front-dist.tar.gz \
        https://github.com/taigaio/taiga-front-dist/archive/${TAIGA_FRONT_VERSION}-stable.tar.gz; \
    echo "${TAIGA_FRONT_SHA256SUM}  taiga-front-dist.tar.gz" | sha256sum -c; \
    tar -xzf taiga-front-dist.tar.gz; \
    mv taiga-front-dist-${TAIGA_FRONT_VERSION}-stable/dist /opt/taiga-front; \
    rm -r taiga-front-dist.tar.gz taiga-front-dist-${TAIGA_FRONT_VERSION}-stable; \
    \
    # Removes origin from "api" URL. By default, the API is served on port
    # 8080. Also, the URL doesn't have to be absolute, so this make the
    # default configuration more generic.
    sed -i 's|http://localhost:8000||' /opt/taiga-front/conf.example.json; \
    mv /opt/taiga-front/conf.example.json /etc/opt/taiga-front/conf.json; \
    ln -s /etc/opt/taiga-front/conf.json /opt/taiga-front/conf.json; \
    \
    find /opt/taiga-front -type d -exec chmod 755 '{}' +; \
    find /opt/taiga-front -type f -exec chmod 644 '{}' +
COPY root /
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
