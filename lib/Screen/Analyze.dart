import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
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
  Interpreter? _wrinkleInterpreter;
  FaceDetector? _faceDetector;

  File? _image;
  String _resultAcne = "";
  String _resultType = "";
  String _resultTone = "";
  String _resultWrinkle = "";
  String _precautions = "";
  bool _isLoading = false;
  bool _isError = false;
  String _imagePath = "";
  final ImagePicker _picker = ImagePicker();
  double _progress = 0.0;

  final List<String> _skinTypes = ["Dry", "Normal", "Oily"];
  final List<String> _skinTones = [
    "Fair / Light",
    "Medium / Tan",
    "Dark / Deep",
  ];
  final List<String> _acneLabels = ["Acne", "Normal"];
  final List<String> _wrinkleLabels = ["Wrinkled", "Normal"];
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
    _loadSavedData();
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
      _wrinkleInterpreter = await Interpreter.fromAsset(
        'assets/models/Wrinkles.tflite',
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
      _isError = false;
      _progress = 10;
    });
    await Future.delayed(Duration(milliseconds: 1000));
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
        _resultType = "";
        _resultTone = "";
        _resultWrinkle = "";
        _precautions = "";
        _isError = true;
        _progress = 0;
      });
      return;
    }
    setState(() {
      _progress = 50;
    });
    await Future.delayed(Duration(milliseconds: 1000));
    _processImage(image);
  }

  /// 🔹 Process Image & Run All Three Models
  // Future<void> _processImage(File image) async {
  //   Uint8List imgBytes = await image.readAsBytes();
  //   var input = _preprocessImage(imgBytes);
  //
  //   var outputAcne = List<List<double>>.filled(1, List.filled(2, 0.0));
  //   var outputType = List<List<double>>.filled(1, List.filled(3, 0.0));
  //   var outputTone = List<List<double>>.filled(1, List.filled(3, 0.0));
  //   var outputWrinkle = List<List<double>>.filled(1, List.filled(2, 0.0));
  //
  //   _acneInterpreter!.run(input, outputAcne);
  //   _skinTypeInterpreter!.run(input, outputType);
  //   _skinToneInterpreter!.run(input, outputTone);
  //   _wrinkleInterpreter!.run(input, outputWrinkle);
  //
  //   int acneIndex = outputAcne[0].indexOf(
  //     outputAcne[0].reduce((a, b) => a > b ? a : b),
  //   );
  //   int typeIndex = outputType[0].indexOf(
  //     outputType[0].reduce((a, b) => a > b ? a : b),
  //   );
  //   int toneIndex = outputTone[0].indexOf(
  //     outputTone[0].reduce((a, b) => a > b ? a : b),
  //   );
  //
  //   int wrinkleIndex = outputWrinkle[0].indexOf(
  //     outputWrinkle[0].reduce((a, b) => a > b ? a : b),
  //   );
  //
  //   _acneInterpreter!.run(input, outputAcne);
  //   setState(() {
  //     _progress = 70;
  //   });
  //   await Future.delayed(Duration(milliseconds: 1000));
  //
  //   _skinTypeInterpreter!.run(input, outputType);
  //   setState(() {
  //     _progress = 85;
  //   });
  //   await Future.delayed(Duration(milliseconds: 1000));
  //   _wrinkleInterpreter!.run(input, outputType);
  //   setState(() {
  //     _progress = 90;
  //   });
  //   await Future.delayed(Duration(milliseconds: 1000));
  //   _skinToneInterpreter!.run(input, outputTone);
  //   setState(() {
  //     _progress = 100;
  //   });
  //   setState(() {
  //     _resultAcne = "${_acneLabels[acneIndex]}";
  //     _resultType = "${_skinTypes[typeIndex]}";
  //     _resultTone = "${_skinTones[toneIndex]}";
  //     _resultWrinkle = _wrinkleLabels[wrinkleIndex];
  //     _precautions = _getPrecautions(
  //       _skinTypes[typeIndex],
  //       _acneLabels[acneIndex],
  //       _skinTones[toneIndex],
  //       _wrinkleLabels[wrinkleIndex],
  //
  //     );
  //     _isLoading = false;
  //   });
  // }
  Future<void> _processImage(File image) async {
    try {
      Uint8List imgBytes = await image.readAsBytes();
      var input = _preprocessImage(imgBytes);

      // Get actual output shapes dynamically
      var acneShape = _acneInterpreter!.getOutputTensor(0).shape;
      var typeShape = _skinTypeInterpreter!.getOutputTensor(0).shape;
      var toneShape = _skinToneInterpreter!.getOutputTensor(0).shape;
      var wrinkleShape = _wrinkleInterpreter!.getOutputTensor(0).shape;

      print("Acne Model Output Shape: $acneShape");
      print("Skin Type Model Output Shape: $typeShape");
      print("Skin Tone Model Output Shape: $toneShape");
      print("Wrinkle Model Output Shape: $wrinkleShape");

      // Create dynamic output lists based on actual model output shape
      var outputAcne = List.generate(acneShape[0], (_) => List.filled(acneShape[1], 0.0));
      var outputType = List.generate(typeShape[0], (_) => List.filled(typeShape[1], 0.0));
      var outputTone = List.generate(toneShape[0], (_) => List.filled(toneShape[1], 0.0));
      var outputWrinkle = List.generate(wrinkleShape[0], (_) => List.filled(wrinkleShape[1], 0.0));

      // Run inference for all models
      _acneInterpreter!.run(input, outputAcne);
      setState(() => _progress = 70);
      await Future.delayed(Duration(milliseconds: 500));

      _skinTypeInterpreter!.run(input, outputType);
      setState(() => _progress = 85);
      await Future.delayed(Duration(milliseconds: 500));

      _wrinkleInterpreter!.run(input, outputWrinkle);  // Corrected
      setState(() => _progress = 90);
      await Future.delayed(Duration(milliseconds: 500));

      _skinToneInterpreter!.run(input, outputTone);
      setState(() => _progress = 100);

      // Find the highest probability index for each model's output
      int acneIndex = outputAcne[0].indexOf(outputAcne[0].reduce((a, b) => a > b ? a : b));
      int typeIndex = outputType[0].indexOf(outputType[0].reduce((a, b) => a > b ? a : b));
      int toneIndex = outputTone[0].indexOf(outputTone[0].reduce((a, b) => a > b ? a : b));
      int wrinkleIndex = outputWrinkle[0].indexOf(outputWrinkle[0].reduce((a, b) => a > b ? a : b));

      // Update UI state
      setState(() {
        _resultAcne = _acneLabels[acneIndex];
        _resultType = _skinTypes[typeIndex];
        _resultTone = _skinTones[toneIndex];
        _resultWrinkle = _wrinkleLabels[wrinkleIndex];
        _precautions = _getPrecautions(
          _skinTypes[typeIndex],
          _acneLabels[acneIndex],
          _skinTones[toneIndex],
          _wrinkleLabels[wrinkleIndex],
        );
        _isLoading = false;
      });

    } catch (e, stackTrace) {
      print("❌ Error processing image: $e");
      print(stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getPrecautions(String skinType, String acneStatus, String skinTone ,String wrinkleStatus) {
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
    if (wrinkleStatus == "Wrinkled") {
      precautions += "• Stay hydrated to keep skin elastic.\n";
      precautions += "• Use anti-aging serums with retinol.\n";
      precautions += "• Avoid excessive sun exposure.\n";
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

  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _resultAcne = prefs.getString('acneStatus') ?? "";
      _resultType = prefs.getString('skinType') ?? "";
      _resultTone = prefs.getString('skinTone') ?? "";
      _resultWrinkle = prefs.getString('wrinkles') ?? "";
      _precautions = prefs.getString('precautions') ?? "";
      _imagePath = prefs.getString('imagePath') ?? "";

      if (_imagePath.isNotEmpty) {
        _image = File(_imagePath);
      }
    });
  }

  /// ✅ Save details & image path
  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('acneStatus', _resultAcne);
    await prefs.setString('skinType', _resultType);
    await prefs.setString('skinTone', _resultTone);
    await prefs.setString('wrinkles', _resultWrinkle);
    await prefs.setString('precautions', _precautions);

    if (_image != null) {
      await prefs.setString('imagePath', _image!.path);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("✅ Details & Image Saved!")));
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.white,
      child: Container(height: 200, width: 200, color: Colors.grey),
    );
  }

  Widget _buildProgressBar() {
    String progressText = "Processing...";
    if (_progress >= 30 && _progress < 50) {
      progressText = "Detecting Face...";
    } else if (_progress >= 50 && _progress < 70) {
      progressText = "Analyzing Acne...";
    } else if (_progress >= 70 && _progress < 85) {
      progressText = "Analyzing Skin Type...";
    } else if (_progress >= 85 && _progress < 90) {
      progressText = "Analyzing Skin Tone...";
    } else if (_progress >= 90 && _progress < 100) {
      progressText = "Analyzing Wrinkles...";
    }
    else if (_progress == 100) {
      progressText = "Analysis Complete!";
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: _progress / 100,
            backgroundColor: Colors.grey[300],
            color: Colors.deepPurple.shade100,
            minHeight: 10,
          ),
          SizedBox(height: 8),
          Text(progressText, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Skin Analyzer"),
        backgroundColor: Colors.deepPurple[100],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10),

            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child:
                  _isLoading
                      ? _buildShimmerEffect()
                      : (_image != null
                          ? Image.file(
                            _image!,
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                          )
                          : Icon(Icons.image, size: 200, color: Colors.grey)),
            ),
            if (_isLoading) _buildProgressBar(),
            if (_isError)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "Error: No face detected! Please try again",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            _isLoading
                ? Center(
                  child: SpinKitFadingCircle(
                    color: Colors.deepPurple.shade100,
                    size: 50.0,
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_resultAcne.isNotEmpty ||
                          _resultType.isNotEmpty ||
                          _resultTone.isNotEmpty ||
                          _resultWrinkle.isNotEmpty ||
                          _precautions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_progress >= 100) ...[
                                _buildField(
                                  "Acne Status",
                                  '${_resultAcne}',
                                  Colors.black,
                                ),
                                _buildFieldselct(
                                  "Skin Type",
                                  _resultType.isNotEmpty ? _resultType : null,
                                  _skinTypes,
                                  (newValue) {
                                    setState(() {
                                      _resultType = newValue!;
                                    });
                                  },
                                ),
                                _buildFieldselct(
                                  "Skin Tone",
                                  _resultTone.isNotEmpty ? _resultTone : null,
                                  _skinTones,
                                  (newValue) {
                                    setState(() {
                                      _resultTone = newValue!;
                                    });
                                  },
                                ),
                                _buildFieldselct(
                                  "Wrinkles",
                                  _resultWrinkle.isNotEmpty ? _resultWrinkle : null,
                                  _wrinkleLabels,
                                      (newValue) {
                                    setState(() {
                                      _resultTone = newValue!;
                                    });
                                  },
                                ),
                                _buildField(
                                  "Precaution",
                                  '${_precautions}',
                                  Colors.black,
                                ),
                              ],
                            ],
                          ),
                        )
                      else
                        Center(
                          child: Text(
                            "📸 Upload an image to analyze your skin!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),

            if (_resultAcne.isNotEmpty ||
                _resultType.isNotEmpty ||
                _resultTone.isNotEmpty ||
                _resultWrinkle.isNotEmpty ||
                _precautions.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: _saveData, child: Text("Save")),

                  // SizedBox(width: 10),
                  // ElevatedButton.icon(
                  //   onPressed:
                  //       _isLoading ? null : () => _pickImage(ImageSource.gallery),
                  //   icon: Icon(Icons.image),
                  //   label: Text("Gallery"),
                  // ),
                ],
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200], // Light background like input field
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldselct(
    String label,
    String? selectedValue,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value:
                    selectedValue!.isNotEmpty
                        ? selectedValue
                        : null, // Allow empty value
                hint: Text("Select $label"), // Placeholder when empty
                onChanged: onChanged,
                items:
                    options.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
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
