import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class SkinClassifierScreen extends StatefulWidget {
  @override
  _SkinClassifierScreenState createState() => _SkinClassifierScreenState();
}

class _SkinClassifierScreenState extends State<SkinClassifierScreen> {
  Interpreter? _skinTypeInterpreter;
  Interpreter? _skinToneInterpreter;

  File? _image;
  String _resultType = "📸 Upload an image to detect skin type & tone!";
  String _resultTone = "";
  bool _isLoading = false; // 🔄 Loading state

  final ImagePicker _picker = ImagePicker();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(enableContours: false, enableLandmarks: false),
  );

  final List<String> _skinTypes = ["Dry", "Normal", "Oily"];
  final List<String> _skinTones = ["Fair / Light", "Medium / Tan", "Dark / Deep"];

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  /// ✅ Load Both TFLite Models
  Future<void> _loadModels() async {
    try {
      _skinTypeInterpreter = await Interpreter.fromAsset('assets/models/skin_type_model.tflite');
      _skinToneInterpreter = await Interpreter.fromAsset('assets/models/skintonemodel.tflite'); // Fixed model name
      print("✅ Models Loaded Successfully!");
    } catch (e) {
      print("❌ Model loading error: $e");
    }
  }

  /// ✅ Pick Image from Camera/Gallery
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    setState(() {
      _image = imageFile;
      _isLoading = true; // 🔄 Start loading
    });

    _processImage(imageFile);
  }

  /// 🔹 Process Image & Predict Skin Type & Tone
  Future<void> _processImage(File image) async {
    Uint8List imgBytes = await image.readAsBytes();
    var input = _preprocessImage(imgBytes);

    var outputType = List<List<double>>.filled(1, List.filled(3, 0.0));
    var outputTone = List<List<double>>.filled(1, List.filled(3, 0.0));

    _skinTypeInterpreter!.run(input, outputType);
    _skinToneInterpreter!.run(input, outputTone);

    int typeIndex = outputType[0].indexOf(outputType[0].reduce((a, b) => a > b ? a : b));
    int toneIndex = outputTone[0].indexOf(outputTone[0].reduce((a, b) => a > b ? a : b));

    setState(() {
      _resultType = "🎯 **Skin Type:** ${_skinTypes[typeIndex]}";
      _resultTone = "🎨 **Skin Tone:** ${_skinTones[toneIndex]}";
      _isLoading = false; // ✅ Stop loading
    });
  }

  /// 📌 Preprocess Image for Model
  List<List<List<List<double>>>> _preprocessImage(Uint8List imgBytes) {
    img.Image image = img.decodeImage(imgBytes)!;
    img.Image resizedImage = img.copyResize(image, width: 150, height: 150);

    return List.generate(
      1,
          (_) => List.generate(
        150,
            (y) => List.generate(150, (x) {
          img.Color pixel = resizedImage.getPixel(x, y);
          return [
            (pixel.r - 127.5) / 127.5,
            (pixel.g - 127.5) / 127.5,
            (pixel.b - 127.5) / 127.5,
          ];
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Skin Type & Tone Detector"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(
              _image!,
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            )
                : Icon(Icons.image, size: 200, color: Colors.grey),
            SizedBox(height: 20),

            // 🔄 Show Loading Indicator
            _isLoading
                ? CircularProgressIndicator()
                : Column(
              children: [
                Text(_resultType, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text(_resultTone, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),

            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera),
                  label: Text("Camera"),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.image),
                  label: Text("Gallery"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _skinTypeInterpreter?.close();
    _skinToneInterpreter?.close();
    super.dispose();
  }
}
