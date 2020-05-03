from django.conf import settings
from django.http import HttpResponse
import logging
from random import randint

from django.shortcuts import render

logger = logging.getLogger(__name__)


def index(request):
    rnd = randint(1, 100)
    logger.info("Hello from log", extra={'random': rnd})

    return render(request, 'index.html', context={
        "random": rnd,
        "secret": settings.SUPER_SECRET
    })
