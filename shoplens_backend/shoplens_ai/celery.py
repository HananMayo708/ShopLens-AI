from __future__ import absolute_import, unicode_literals
import os
from celery import Celery
from django.conf import settings

# Set the default Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'shoplens_ai.settings')

# Create Celery app
app = Celery('shoplens_ai')

# Using a string here means the worker doesn't have to serialize
# the configuration object to child processes.
app.config_from_object('django.conf:settings', namespace='CELERY')

# Load task modules from all registered Django apps
app.autodiscover_tasks()

# CRITICAL FIX for Windows - use solo pool and disable prefork
app.conf.worker_pool = 'solo'
app.conf.task_always_eager = False
app.conf.task_store_eager_result = False
