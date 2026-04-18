// imports
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // The "Default Camera" magic
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// main method that runs the application
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    const MaterialApp(home: PlantScoutPro(), debugShowCheckedModeBanner: false),
  );
}

// main application widget PlantScoutPro
class PlantScoutPro extends StatefulWidget {
  // default constructor
  const PlantScoutPro({super.key});

  // create state
  @override
  State<PlantScoutPro> createState() => _PlantScoutProState();
}

// define PlantScoutPro State
class _PlantScoutProState extends State<PlantScoutPro> {
  // class fields
  // user image represents the image the user takes
  File? _userImage;
  // result markdown stores the returned plant information to display
  // to the user
  String _resultMarkdown =
      "### Ready to Identify some plants\nTap the button to use your phone's camera.";
  // boolean variable for program control
  bool _isProcessing = false;
  // image picker object used for taking a picture with the device's camera
  final ImagePicker _picker = ImagePicker();

  // class method for taking a picture and sending the prompt
  Future<void> _openDefaultCamera() async {
    // get user to take photo
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    // if no photo taken exit method
    if (photo == null) return;
    // update class fields
    setState(() {
      _userImage = File(photo.path);
      _isProcessing = true;
      _resultMarkdown = "### Identifying...\nConsulting Gemini cloud.";
    });
    // send prompt to Gemini Flash 2.5
    try {
      final apiKey = dotenv.env['GEMINI']!;
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

      // turn the photo into byte representation
      final bytes = await photo.readAsBytes();
      // define the prompt with both a static text prompt and the user's photo
      final content = [
        Content.multi([
          TextPart(
            "Identify this plant. Use Markdown: ## Common Name, ## Scientific Name, **Toxicity**, and **Care Tips**.",
          ),
          DataPart('image/jpeg', bytes),
        ]),
      ];
      // send the prompt to the model
      final response = await model.generateContent(content);
      // update the response markdown with the response if it was not null
      setState(() => _resultMarkdown = response.text ?? "Could not identify.");
    } catch (e) {
      // on exception, display the error to the user
      setState(() => _resultMarkdown = "## Error\n$e");
    } finally {
      // update boolean variable
      setState(() => _isProcessing = false);
    }
  }

  // build method that creates the widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // application's appbar
      appBar: AppBar(
        title: const Text("Picture That"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      // main body
      body: SingleChildScrollView(
        child: Column(
          children: [
            // if the user has taken a photo display that image
            if (_userImage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    _userImage!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
            // markdown display where final message and other messages are
            // shown to the user
            Padding(
              padding: const EdgeInsets.all(20),
              child: MarkdownBody(data: _resultMarkdown),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      // button that calls the _openDefaultCamera method
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        onPressed: _isProcessing ? null : _openDefaultCamera,
        label: Text(
          _userImage == null ? "Open Native Camera" : "Identify Another",
        ),
        // if the application is processing show a circular progress indicator
        // otherwise show camera icon
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.camera_alt),
      ),
      // set the location of the button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
