SECRET_KEY = '9%pno@m688el28@2+^y4v^&6wluqk-g#j#d7$dsjtht)o30dn1'

ALLOWED_HOSTS = [
    '127.0.0.1',
    'localhost',
]

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'taiga',
        'USER': 'taiga',
        'PASSWORD': 'changeme',
        'HOST': 'database',
        'PORT': '5432',
    }
}

EVENTS_PUSH_BACKEND = "taiga.events.backends.rabbitmq.EventsPushBackend"
EVENTS_PUSH_BACKEND_OPTIONS = {"url": "amqp://guest:guest@broker/taiga"}
