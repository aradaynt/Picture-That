import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Get available cameras before launching the app
  cameras = await availableCameras();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PlantIdentifierApp(),
    ),
  );
}

class PlantIdentifierApp extends StatefulWidget {
  const PlantIdentifierApp({Key? key}) : super(key: key);

  @override
  State<PlantIdentifierApp> createState() => _PlantIdentifierAppState();
}

class _PlantIdentifierAppState extends State<PlantIdentifierApp> {
  late CameraController _controller;
  ImageLabeler? _imageLabeler;

  bool _isReady = false;
  bool _isProcessing = false;
  String _resultText = "Ready to identify plants!";

  @override
  void initState() {
    super.initState();
    _initializeCameraAndModel();
  }

  Future<void> _initializeCameraAndModel() async {
    // 1. Initialize the Camera (using the first back-facing camera)
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller.initialize();

    // 2. Load the custom TFLite model for ML Kit
    // IMPORTANT: Change this string to match your plant model's filename!
    final modelPath = await _getModelPath('1.tflite');

    final options = LocalLabelerOptions(
      modelPath: modelPath,
      confidenceThreshold: 0.0, // Only show results with 40%+ confidence
    );
    _imageLabeler = ImageLabeler(options: options);

    setState(() {
      _isReady = true;
    });
  }

  // ML Kit requires the model to be a physical file on the device.
  // This helper securely copies the model from your assets to phone storage.
  Future<String> _getModelPath(String assetName) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$assetName';
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);

    if (!await file.exists()) {
      final byteData = await rootBundle.load('assets/$assetName');
      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
    }
    return file.path;
  }

  Future<void> _takePictureAndProcess() async {
    if (_isProcessing || !_controller.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
      _resultText = "Analyzing plant...";
    });

    try {
      // 1. Snap the photo
      final XFile imageFile = await _controller.takePicture();

      // 2. Feed the photo to Google ML Kit
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final List<ImageLabel> labels = await _imageLabeler!.processImage(
        inputImage,
      );

      // 3. Format the results
      if (labels.isEmpty) {
        _resultText = "Couldn't identify this confidently.";
      } else {
        _resultText = "Top Results:\n";
        // Loop through the top 3 guesses
        for (ImageLabel label in labels.take(3)) {
          _resultText +=
              '${label.label} (${(label.confidence * 100).toStringAsFixed(1)}%)\n';
        }
      }
    } catch (e) {
      _resultText = "Error analyzing image: $e";
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _imageLabeler?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading spinner while the camera and AI model boot up
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Identifier'),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          // Top section: Camera Preview
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: CameraPreview(_controller),
            ),
          ),

          // Bottom section: Results & Button
          // Bottom section: Results & Button
          Expanded(
            flex: 1, // (Or change to 2 if you want the bottom section taller!)
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Wrap the text in Expanded and SingleChildScrollView
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _resultText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 2. The button stays safely at the bottom!
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _takePictureAndProcess,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text(
                      'Identify Plant',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor: Colors.green[600],
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
