import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // The "Default Camera" magic
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    const MaterialApp(home: PlantScoutPro(), debugShowCheckedModeBanner: false),
  );
}

class PlantScoutPro extends StatefulWidget {
  const PlantScoutPro({super.key});
  @override
  State<PlantScoutPro> createState() => _PlantScoutProState();
}

class _PlantScoutProState extends State<PlantScoutPro> {
  File? _userImage;
  String _resultMarkdown =
      "### Ready to Identify some plants\nTap the button to use your phone's camera.";
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _openDefaultCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo == null) return;
    setState(() {
      _userImage = File(photo.path);
      _isProcessing = true;
      _resultMarkdown = "### Identifying...\nConsulting Gemini cloud.";
    });
    try {
      final apiKey = dotenv.env['GEMINI']!;
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

      final bytes = await photo.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
            "Identify this plant. Use Markdown: ## Common Name, ## Scientific Name, **Toxicity**, and **Care Tips**.",
          ),
          DataPart('image/jpeg', bytes),
        ]),
      ];
      final response = await model.generateContent(content);
      setState(() => _resultMarkdown = response.text ?? "Could not identify.");
    } catch (e) {
      setState(() => _resultMarkdown = "## Error\n$e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Picture That"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: MarkdownBody(data: _resultMarkdown),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        onPressed: _isProcessing ? null : _openDefaultCamera,
        label: Text(
          _userImage == null ? "Open Native Camera" : "Identify Another",
        ),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
