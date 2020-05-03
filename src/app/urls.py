from django.urls import path
from app.views import index
from django.http import JsonResponse

urlpatterns = [
    path('health', lambda request: JsonResponse({"status": 'OK'}), name='health'),
    path('', index),
]
