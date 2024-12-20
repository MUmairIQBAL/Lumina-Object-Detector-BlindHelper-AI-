import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:lumina_tech/screens/splash_screen.dart';
// created by Muhammad Umair Iqbal Awan

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error getting cameras: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Object Detection App',
      theme: ThemeData.dark(),
      home: const SplashScreen(), // Set SplashScreen as the initial screen
    );
  }
}
