import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../main.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  ObjectDetectionScreenState createState() => ObjectDetectionScreenState();
}

class ObjectDetectionScreenState extends State<ObjectDetectionScreen> with WidgetsBindingObserver {
  CameraController? controller;
  FlutterTts flutterTts = FlutterTts();
  bool isProcessing = false;
  String detectedObject = 'Point camera at an object for analysis';
  double? confidence;
  bool isCameraReady = false;
  List<dynamic> alternativeObjects = [];
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeCamera();
    setupTTS();
    startListening();
    startContinuousCapture();
  }

  Future<void> setupTTS() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> initializeCamera() async {
    if (cameras.isEmpty) {
      print('No cameras available');

      return;
    }

    controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller!.initialize();
      if (mounted) {
        setState(() {
          isCameraReady = true;
        });
        startContinuousCapture();
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void startListening() async {
    bool available = await speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          startListening();
        }
      },
      onError: (error) {
        print('Speech recognition error: $error');
      },
    );

    if (available) {
      setState(() {
        isListening = true;
      });
      speech.listen(
        onResult: (result) {
          String command = result.recognizedWords.toLowerCase();
          if (command.contains("stop")) {
            flutterTts.stop();
            exitApp();
          }
        },
      );
    }
  }

  void exitApp() {
    Future.delayed(Duration.zero, () {
      SystemNavigator.pop();
    });
  }

  void startContinuousCapture() {
    Future.delayed(const Duration(seconds: 1), () async {
      if (isCameraReady && !isProcessing) {
        await captureAndDetect();
      }
      if (mounted) {
        startContinuousCapture();
      }
    });
  }

  Future<void> captureAndDetect() async {
    if (controller == null || !controller!.value.isInitialized || isProcessing) {
      return;
    }

    setState(() {
      isProcessing = true;
      detectedObject = 'Analyzing...';
      alternativeObjects = [];
    });

    try {
      await controller!.setFlashMode(FlashMode.auto);
      await controller!.setFocusMode(FocusMode.auto);
      await Future.delayed(const Duration(milliseconds: 500));

      final XFile photo = await controller!.takePicture();
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      final File imageFile = File(tempPath);
      await File(photo.path).copy(tempPath);

      await sendImageToAPI(imageFile);

      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      print('Error during capture: $e');
      setState(() {
        detectedObject = 'Error during capture';
      });
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> sendImageToAPI(File imageFile) async {
    final uri = Uri.parse('http://172.25.99.178:8000/detection/detect/');

    try {
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path, filename: path.basename(imageFile.path)));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        setState(() {
          detectedObject = result['detections'][0]['name'];
          confidence = result['detections'][0]['confidence'];
          alternativeObjects = result['detections'];
        });

        await speakTopDetections();
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending image to API: $e');
      setState(() {
        detectedObject = 'Network error';
      });
    }
  }

  Future<void> speakTopDetections() async {
    alternativeObjects.sort((a, b) => b['confidence'].compareTo(a['confidence']));
    List top3Detections = alternativeObjects.take(3).toList();
    bool hasClearObject = top3Detections.any((det) => det['confidence'] >= 0.50);

    if (!hasClearObject) {
      await flutterTts.speak("Object is not clear");
      return;
    }

    Map<String, int> objectCount = {};
    String message = '';

    for (var detection in top3Detections) {
      String objectName = detection['name'];
      objectCount[objectName] = (objectCount[objectName] ?? 0) + 1;

      String displayName = objectCount[objectName]! > 1
          ? '$objectName ${objectCount[objectName]}'
          : objectName;

      message += '$displayName, ';
    }

    await flutterTts.speak(message);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (controller != null) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        controller!.dispose();
        setState(() {
          isCameraReady = false;
        });
      } else if (state == AppLifecycleState.resumed) {
        if (!isCameraReady) {
          initializeCamera();
        }
      }
    }
  }

  @override
  void dispose() {
    speech.stop();
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraReady || controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
        backgroundColor: Colors.white,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white.withOpacity(0.8),
          title: const Text(
            'Lumina Tech',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller!),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white.withOpacity(0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    detectedObject,
                    style: const TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (confidence != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Confidence: ${(confidence! * 100).round()}%',
                      style: const TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  ],
                  if (alternativeObjects.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Alternative detections:',
                      style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.7)),
                    ),
                    ...alternativeObjects.map((alt) => Text(
                      '${alt['name']} (${(alt['confidence'] * 100).round()}%)',
                      style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.6)),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
