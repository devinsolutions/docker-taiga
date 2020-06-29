from django.core.management.utils import get_random_secret_key

from .common import *

# /admin should redirect to /admin/
APPEND_SLASH = True

ALLOWED_HOSTS = [
    # Useful for health checks
    'localhost',
]

ADMINS = []

# The default configuration assumes the app is behind a trusted proxy, which is not necessarily
# true and if it's not, then the default configuration is insecure.
USE_X_FORWARDED_HOST = False
SECURE_PROXY_SSL_HEADER = None

SITES['api']['domain'] = SITES['front']['domain'] = 'localhost:8080'

# Prevent secret key reuse
SECRET_KEY = ''

MEDIA_ROOT = '/srv/taiga-back/media'
STATIC_ROOT = '/srv/taiga-back/static'

MEDIA_URL = "http://localhost:8080/media/"
STATIC_URL = "http://localhost:8080/static/"

# Helps with cache busting
STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.ManifestStaticFilesStorage'

if 'django.middleware.security.SecurityMiddleware' not in MIDDLEWARE:
    MIDDLEWARE = [
        'django.middleware.security.SecurityMiddleware',
    ] + MIDDLEWARE

SILENCED_SYSTEM_CHECKS = [
    # X-Frame-Options header is set by the server
    'security.W002',
    # CSRF is covered where necessary without CsrfViewMiddleware
    'security.W003',
    # X-Content-Type-Options header is set by the server
    'security.W006',
    # X-XSS-Protection header is set by the server
    'security.W007',
]

# Load user-provided settings
try:
    with open('/etc/opt/taiga-back/settings.py') as f:
        exec(f.read())
except FileNotFoundError:
    pass

if not SECRET_KEY:
    print((
        '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n'
        'A valid secret key was not specified in the configuration file. A temporary\n'
        'one will be generated for you, but it will be lost on the application restart.\n'
        'Please, provide a valid secret key as "SECRET_KEY" in the configuration file.\n'
        'See https://docs.djangoproject.com/en/1.11/ref/settings/#std:setting-SECRET_KEY\n'
        'for more details.'
    ), file=sys.stderr)
    SECRET_KEY = get_random_secret_key()
