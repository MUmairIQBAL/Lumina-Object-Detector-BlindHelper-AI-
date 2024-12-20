# detection/yolo.py
import torch

# Load the YOLOv5 model (make sure you have the 'yolov5' folder in the root directory)
model = torch.hub.load('yolov5', 'yolov5s', source='local')  # use 'yolov5s' or any model available

def detect_objects(image_path):
    # Perform inference
    results = model(image_path)
    return results.pandas().xyxy[0].to_dict(orient="records")  # return detection results as a list of dictionaries
