import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';

void main() {
  runApp(const DicteeApp());
}

class DicteeApp extends StatelessWidget {
  const DicteeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Point à la ligne',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DicteeHomePage(),
    );
  }
}

class DicteeHomePage extends StatefulWidget {
  const DicteeHomePage({super.key});

  @override
  State<DicteeHomePage> createState() => _DicteeHomePageState();
}

class _DicteeHomePageState extends State<DicteeHomePage> {
  File? _image;
  String _extractedText = "Aucune photo analysée pour le moment.";
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setSpeechRate(0.4); // Vitesse adaptée pour une dictée (plus lente)
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _pickImageAndRecognize() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() {
      _image = File(photo.path);
      _extractedText = "Analyse en cours...";
    });

    final inputImage = InputImage.fromFilePath(photo.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    setState(() {
      _extractedText = recognizedText.text.isEmpty ? "Aucun texte détecté." : recognizedText.text;
    });
  }

  Future<void> _speakText() async {
    if (_extractedText.isNotEmpty && _extractedText != "Aucune photo analysée pour le moment." && _extractedText != "Analyse en cours...") {
      await _flutterTts.speak(_extractedText);
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Point à la ligne - Dictée')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImageAndRecognize,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Prendre en photo la dictée'),
            ),
            const SizedBox(height: 15),
            if (_image != null)
              SizedBox(
                height: 150,
                child: Image.file(_image!),
              ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _speakText,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Lire la dictée'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _stopSpeaking,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              'Texte reconnu :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _extractedText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
