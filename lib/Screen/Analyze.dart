import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:google_ml_kit/google_ml_kit.dart';

class SkinAnalyzerScreen extends StatefulWidget {
  @override
  _SkinAnalyzerScreenState createState() => _SkinAnalyzerScreenState();
}

class _SkinAnalyzerScreenState extends State<SkinAnalyzerScreen> {
  Interpreter? _acneInterpreter;
  Interpreter? _skinTypeInterpreter;
  Interpreter? _skinToneInterpreter;
  FaceDetector? _faceDetector;

  File? _image;
  String _resultAcne = "";
  String _resultType = "";
  String _resultTone = "";
  String _precautions = "";
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> _skinTypes = ["Dry", "Normal", "Oily"];
  final List<String> _skinTones = [
    "Fair / Light",
    "Medium / Tan",
    "Dark / Deep",
  ];
  final List<String> _acneLabels = ["Acne", "Normal"];

  @override
  void initState() {
    super.initState();
    _loadModels();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
      ),
    );
  }

  /// ✅ Load all three models
  Future<void> _loadModels() async {
    try {
      _acneInterpreter = await Interpreter.fromAsset(
        'assets/models/model_unquant.tflite',
      );
      _skinTypeInterpreter = await Interpreter.fromAsset(
        'assets/models/skin_type_model.tflite',
      );
      _skinToneInterpreter = await Interpreter.fromAsset(
        'assets/models/skintonemodel.tflite',
      );
      print("✅ Models Loaded Successfully!");
    } catch (e) {
      print("❌ Error loading models: $e");
    }
  }

  /// ✅ Pick image from camera/gallery
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    setState(() {
      _image = imageFile;
      _isLoading = true;
    });

    _detectFaceAndProcess(imageFile);
  }

  /// 🔹 Detect Face First, Then Process Image
  Future<void> _detectFaceAndProcess(File image) async {
    final InputImage inputImage = InputImage.fromFile(image);
    final List<Face> faces = await _faceDetector!.processImage(inputImage);

    if (faces.isEmpty) {
      setState(() {
        _isLoading = false;
        _resultAcne = "";
        _resultType = "⚠ No face detected! Please upload a clear face image.";
        _resultTone = "";
        _precautions = "";
      });
      return;
    }

    _processImage(image);
  }

  /// 🔹 Process Image & Run All Three Models
  Future<void> _processImage(File image) async {
    Uint8List imgBytes = await image.readAsBytes();
    var input = _preprocessImage(imgBytes);

    var outputAcne = List<List<double>>.filled(1, List.filled(2, 0.0));
    var outputType = List<List<double>>.filled(1, List.filled(3, 0.0));
    var outputTone = List<List<double>>.filled(1, List.filled(3, 0.0));

    _acneInterpreter!.run(input, outputAcne);
    _skinTypeInterpreter!.run(input, outputType);
    _skinToneInterpreter!.run(input, outputTone);

    int acneIndex = outputAcne[0].indexOf(
      outputAcne[0].reduce((a, b) => a > b ? a : b),
    );
    int typeIndex = outputType[0].indexOf(
      outputType[0].reduce((a, b) => a > b ? a : b),
    );
    int toneIndex = outputTone[0].indexOf(
      outputTone[0].reduce((a, b) => a > b ? a : b),
    );

    setState(() {
      _resultAcne = "Acne Status : ${_acneLabels[acneIndex]}";
      _resultType = "Skin Type   : ${_skinTypes[typeIndex]}";
      _resultTone = "Skin Tone   : ${_skinTones[toneIndex]}";
      _precautions = _getPrecautions(
        _skinTypes[typeIndex],
        _acneLabels[acneIndex],
        _skinTones[toneIndex],
      );
      _isLoading = false;
    });
  }

  String _getPrecautions(String skinType, String acneStatus, String skinTone) {
    String precautions = "Skin Care Tips: \n";

    // Tips based on skin type
    if (skinType == "Dry") {
      precautions += "• Use a moisturizer regularly.\n";
      precautions += "• Avoid hot showers to prevent drying your skin.\n";
    } else if (skinType == "Oily") {
      precautions += "• Use an oil-free moisturizer.\n";
      precautions +=
          "• Cleanse your skin with a gentle, oil-controlling cleanser.\n";
    } else if (skinType == "Normal") {
      precautions += "• Keep a balanced skincare routine.\n";
      precautions += "• Use a gentle cleanser to maintain skin hydration.\n";
    }

    // Tips based on acne status
    if (acneStatus == "Acne") {
      precautions += "• Avoid touching your face frequently.\n";
      precautions += "• Use a face wash suitable for acne-prone skin.\n";
      precautions += "• Drink plenty of water and eat a balanced diet.\n";
    }

    // Tips based on skin tone
    if (skinTone == "Fair / Light") {
      precautions += "• Apply sunscreen with a high SPF.\n";
      precautions += "• Avoid direct exposure to the sun.\n";
    } else if (skinTone == "Medium / Tan") {
      precautions +=
          "• Apply sunscreen regularly, especially if you're outdoors.\n";
      precautions += "• Stay hydrated and protect your skin from UV rays.\n";
    } else if (skinTone == "Dark / Deep") {
      precautions += "• Use sunscreen to prevent hyperpigmentation.\n";
      precautions += "• Keep your skin moisturized to avoid dryness.\n";
    }

    return precautions;
  }

  /// 📌 Preprocess image for all models
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("Skin Analyzer"),
          backgroundColor: Colors.lightBlueAccent,
        ),

        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10),

              _image != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _image!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                  : Icon(Icons.image, size: 200, color: Colors.grey),
              SizedBox(height: 20),
              _isLoading
                  ? Center(
                    child: SpinKitFadingCircle(
                      color: Colors.blueAccent,
                      size: 50.0,
                    ),
                  )
                  : Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _resultAcne,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              _image != null
                                  ? _resultType
                                  : " 📸 Upload an image to Skin Analyze!",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              _resultTone,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              _precautions,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _isLoading
                            ? null
                            : () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera),
                    label: Text("Camera"),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed:
                        _isLoading
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.image),
                    label: Text("Gallery"),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _acneInterpreter?.close();
    _skinTypeInterpreter?.close();
    _skinToneInterpreter?.close();
    _faceDetector?.close();
    super.dispose();
  }
}
