## Running YOLOv5 Django API

The backend includes two projects. This section explains how to run the YOLOv5 Django API located in the `django_flask_project` directory.

---

### Prerequisites
Ensure the following are installed on your system:
- **Python 3.x**
- **Pip** (Python package manager)
- **Virtualenv** (optional but recommended)

---

### Step-by-Step Guide

You can test the YOLOv5 API endpoint using tools like Postman or curl.

Example Request:

Endpoint: http://127.0.0.1:8000/detection/detect/
Method: POST
Payload: Upload an image file as image.
Using curl:

bash
Copy code
curl -X POST -F "image=@/path/to/image.jpg" http://127.0.0.1:8000/detection/detect/
Expected Response: A JSON object containing detected objects and confidence scores:

json
Copy code
{
  "detections": [
    { "name": "person", "confidence": 0.95 },
    { "name": "dog", "confidence": 0.85 }
  ]
}
Troubleshooting
Port Conflicts: If the default port 8000 is in use, run the server on a different port:

bash
Copy code
python manage.py runserver 8080
Missing YOLOv5 Files: Ensure the yolov5 directory contains all necessary files, including detect.py.

Model Weights: Verify that the YOLOv5 model weights (e.g., best.pt) are properly configured and loaded in detect.py.

This step-by-step guide ensures that the YOLOv5 Django API runs smoothly. If you encounter issues, feel free to open an issue in the repository.




Before running django sever change ip on all loactions
1. In object_detection_screen.dart
2. In setting.py

By changing ip the will work properly
