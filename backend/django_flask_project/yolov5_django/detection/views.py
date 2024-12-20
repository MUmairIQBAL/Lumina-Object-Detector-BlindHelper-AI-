# detection/views.py
from django.http import JsonResponse
from .yolo import detect_objects
from django.views.decorators.csrf import csrf_exempt
from django.core.files.storage import default_storage

@csrf_exempt
def detect_view(request):
    if request.method == 'POST' and 'image' in request.FILES:
        # Save uploaded image
        image = request.FILES['image']
        path = default_storage.save('temp.jpg', image)

        # Run YOLOv5 detection
        results = detect_objects(path)

        # Remove the temporary file after processing
        default_storage.delete(path)

        return JsonResponse({'detections': results})
    return JsonResponse({'error': 'Image not provided'}, status=400)
