# Taiga Docker Image

This is based on the official Python image (Alpine variant) and combines
taiga-back and taiga-front components into a single container, which uses
uWSGI to serve them both.

## Deployment

Consult [Taiga: Setup production environment](
https://taigaio.github.io/taiga-doc/dist/setup-production.html) to learn about
external dependencies and basic configuration options. A very basic deployment
example can be found in `docker-compose.yml` and an advanced one in
`docker-compose.advanced.yml`.

### Configuring taiga-back

taiga-back can be configured using `/etc/opt/taiga-back/settings.py`. See
`files/etc/opt/taiga-back/settings.py` in this repository for the default
configuration and information about all the settings.

### Configuring taiga-front

taiga-back can be configured using `/etc/opt/taiga-front/conf.json`. See
[conf.example.json](
https://github.com/taigaio/taiga-front/blob/stable/conf/conf.example.json) for
the default configuration.

### Configuring uWSGI

uWSGI can be configured using `/usr/local/etc/uwsgi/uwsgi.ini` and/or using
[environmental variables](
https://uwsgi-docs.readthedocs.io/en/latest/Configuration.html#environment-variables
).
This file provides only the basic configuration, since settings defined in it
cannot be overridden using environmental variables. Also, using environmental
variables is the easiest way to extend the default configuration without the
need duplicate contents on the configuration file.

See `Dockerfile` to learn about the variables export by default and their
significance.

#### Graceful shutdown

With the default configuration, uWSGI is shutdown forcefully on `SIGTERM` and
gracefully on `SIGHUP`.

### Persistence

taiga-back persists data such as attachments in `/srv/taiga-back/media`.
**This directory is not a volume by default!**

## Stability

Breaking changes may occur between different image tags, so make sure to
review the changes before upgrading. Images tagged with respective Taiga
version are guaranteed to be stable.
