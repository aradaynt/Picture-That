import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tflite/flutter_tflite.dart'; // Updated import

void main() {
  runApp(const PlantIdentifierApp());
}

class PlantIdentifierApp extends StatelessWidget {
  const PlantIdentifierApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Matcher',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const PlantIdentifierScreen(),
    );
  }
}

class PlantIdentifierScreen extends StatefulWidget {
  const PlantIdentifierScreen({Key? key}) : super(key: key);

  @override
  State<PlantIdentifierScreen> createState() => _PlantIdentifierScreenState();
}

class _PlantIdentifierScreenState extends State<PlantIdentifierScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isLoading = false;

  List<String> _plantDatabase = [];
  List<String> _matchedSpecies = [];

  @override
  void initState() {
    super.initState();
    _loadPlantList();
    _loadModel();
  }

  // 1. Load the text file attached
  Future<void> _loadPlantList() async {
    try {
      final String fileText = await rootBundle.loadString(
        'assets/plantlst.txt',
      );
      // Splitting the file line by line
      final List<String> lines = fileText.split('\n');

      setState(() {
        // Saving as lowercase for case-insensitive comparison later
        _plantDatabase = lines.map((line) => line.toLowerCase()).toList();
      });
    } catch (e) {
      debugPrint("Error loading plantlst.txt: $e");
    }
  }

  // 2. Load the Pre-trained TFLite Model
  Future<void> _loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
      );
    } catch (e) {
      debugPrint("Error loading model: $e");
    }
  }

  // 3. Pick Image from Camera
  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() {
      _isLoading = true;
      _image = File(photo.path);
      _matchedSpecies.clear();
    });

    _classifyAndCompareImage(_image!);
  }

  // 4. Classify Image and Compare with plantlst.txt
  Future<void> _classifyAndCompareImage(File image) async {
    // Get top 10 classifications
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 10,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    List<String> foundMatches = [];

    if (recognitions != null) {
      for (var recognition in recognitions) {
        String label = recognition['label'].toString().toLowerCase().trim();

        // Search the loaded plantlst.txt file line by line to see if the label matches
        for (var databaseEntry in _plantDatabase) {
          // The database entries use the format: "Symbol","Synonym","Scientific Name","Common Name","Family"
          // We check if the classification exists anywhere in the species string
          if (databaseEntry.contains(label) && label.isNotEmpty) {
            foundMatches.add(recognition['label']);
            break; // Stop looking in the database for this specific recognition once found
          }
        }
      }
    }

    setState(() {
      _isLoading = false;
      _matchedSpecies = foundMatches;
    });
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plant Species Matcher')),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, height: 350, fit: BoxFit.cover),
                  )
                else
                  const Text(
                    'Take a picture of a plant to identify it!',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 30),

                if (_isLoading)
                  const CircularProgressIndicator()
                else if (_matchedSpecies.isNotEmpty) ...[
                  const Text(
                    "Matches Found in Your List:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  ..._matchedSpecies.map(
                    (species) => Card(
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        title: Text(
                          species,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else if (_image != null && _matchedSpecies.isEmpty) ...[
                  const Text(
                    "No top 10 classifications matched the attached plant list.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _takePicture,
        icon: const Icon(Icons.camera_alt),
        label: const Text("Take Photo"),
      ),
    );
  }
}
