import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  File? image;
  SkinAnalyzerScreen({super.key, this.image});
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
  bool _isloading = false;
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
    _isloading = true;
    _loadSavedData();
    if (_imagePath == "") {
      widget.image = null;
    }
  }

  //Load all three models
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
      print("Models Loaded Successfully!");
    } catch (e) {
      print("Error loading models: $e");
    }
  }

  //Pick image from camera/gallery
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    setState(() {
      widget.image = imageFile;
      _isLoading = true;
      _isError = false;
      _progress = 10;
    });
    await Future.delayed(Duration(milliseconds: 1000));
    _detectFaceAndProcess(imageFile);
  }

  //Detect Face First, Then Process Image
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
      var outputAcne = List.generate(
        acneShape[0],
        (_) => List.filled(acneShape[1], 0.0),
      );
      var outputType = List.generate(
        typeShape[0],
        (_) => List.filled(typeShape[1], 0.0),
      );
      var outputTone = List.generate(
        toneShape[0],
        (_) => List.filled(toneShape[1], 0.0),
      );
      var outputWrinkle = List.generate(
        wrinkleShape[0],
        (_) => List.filled(wrinkleShape[1], 0.0),
      );

      // Run inference for all models
      _acneInterpreter!.run(input, outputAcne);
      setState(() => _progress = 70);
      await Future.delayed(Duration(milliseconds: 500));

      _skinTypeInterpreter!.run(input, outputType);
      setState(() => _progress = 85);
      await Future.delayed(Duration(milliseconds: 500));

      _wrinkleInterpreter!.run(input, outputWrinkle); // Corrected
      setState(() => _progress = 90);
      await Future.delayed(Duration(milliseconds: 500));

      _skinToneInterpreter!.run(input, outputTone);
      setState(() => _progress = 100);

      // Find the highest probability index for each model's output
      int acneIndex = outputAcne[0].indexOf(
        outputAcne[0].reduce((a, b) => a > b ? a : b),
      );
      int typeIndex = outputType[0].indexOf(
        outputType[0].reduce((a, b) => a > b ? a : b),
      );
      int toneIndex = outputTone[0].indexOf(
        outputTone[0].reduce((a, b) => a > b ? a : b),
      );
      int wrinkleIndex = outputWrinkle[0].indexOf(
        outputWrinkle[0].reduce((a, b) => a > b ? a : b),
      );

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
      print("Error processing image: $e");
      print(stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getPrecautions(
    String skinType,
    String acneStatus,
    String skinTone,
    String wrinkleStatus,
  ) {
    String precautions = "Skin Care Tips:\n\n";
    int score = 100;

    if (skinType == "Dry") {
      precautions += "• Use a moisturizer regularly.\n";
      precautions += "• Avoid hot showers to prevent drying your skin.\n";
      score -= 10;
    } else if (skinType == "Oily") {
      precautions += "• Use an oil-free moisturizer.\n";
      precautions +=
          "• Cleanse your skin with a gentle, oil-controlling cleanser.\n";
      score -= 10;
    } else if (skinType == "Normal") {
      precautions += "• Keep a balanced skincare routine.\n";
      precautions += "• Use a gentle cleanser to maintain skin hydration.\n";
    }

    if (acneStatus == "Acne") {
      precautions += "• Avoid touching your face frequently.\n";
      precautions += "• Use a face wash suitable for acne-prone skin.\n";
      precautions += "• Drink plenty of water and eat a balanced diet.\n";
      score -= 20;
    }

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
      score -= 15;
    }

    precautions += "\nOverall Skin Health Score :  ${score}%\n";
    if (score >= 85) {
      precautions +=
          "Your skin is in excellent condition. Keep up the great care!";
    } else if (score >= 60) {
      precautions +=
          "Your skin is in good condition. Follow the tips above to improve further.";
    } else {
      precautions +=
          "Your skin needs attention. Consistently follow the care tips to improve health.";
    }
    return precautions;
  }

  // Preprocess image for all models
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
    print("call data ");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _resultAcne = prefs.getString('acneStatus') ?? "";
      _resultType = prefs.getString('skinType') ?? "";
      _resultTone = prefs.getString('skinTone') ?? "";
      _resultWrinkle = prefs.getString('wrinkles') ?? "";
      _precautions = prefs.getString('precautions') ?? "";
      _imagePath = prefs.getString('imagePath') ?? "";

      if (_imagePath.isNotEmpty) {
        widget.image = File(_imagePath);
      }

      _isloading = false;
      print(" acne $_resultAcne");
      print(" image $_imagePath");
    });
  }

  //Save details & image path
  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('acneStatus', _resultAcne);
    await prefs.setString('skinType', _resultType);
    await prefs.setString('skinTone', _resultTone);
    await prefs.setString('wrinkles', _resultWrinkle);
    await prefs.setString('precautions', _precautions);

    if (widget.image != null) {
      await prefs.setString('imagePath', widget.image!.path);
    }
    // Debugging: Print saved values
    print("Saved Data:");
    print("Acne Status: ${prefs.getString('acneStatus')}");
    print("Skin Type: ${prefs.getString('skinType')}");
    print("Skin Tone: ${prefs.getString('skinTone')}");
    print("Wrinkles: ${prefs.getString('wrinkles')}");
    print("Precautions: ${prefs.getString('precautions')}");
    print("Image Path: ${prefs.getString('imagePath')}");
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Details Saved!")));

    // final userId = FirebaseAuth.instance.currentUser?.uid;
    // final Timestamp now = Timestamp.fromDate(DateTime.now());
    // await FirebaseFirestore.instance
    //     .collection("User")
    //     .doc("fireid")
    //     .collection("AnalyseSkin")
    //     .doc(userId)
    //     .set({
    //   "acneStatus": _resultAcne,
    //   "skinType": _resultType,
    //   "skinTone": _resultTone,
    //   "wrinkles": _resultWrinkle,
    //   "precautions": _precautions,
    //   "imagePath": widget.image!.path,
    //
    // }, SetOptions(merge: true)); //  use the right key!
    // //await prefs.setString('reminder_type', selectedReminder);
    //
    // await prefs.setString(
    //   'notifications_enabled_at',
    //   now.toDate().toIso8601String(),
    // );
    // print("image path ${widget.image!.path}");
    // print("image  ${widget.image}");
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Container(height: 200, width: 200, color: Colors.grey),
      ),
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
    } else if (_progress == 100) {
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
      body:
          _isloading
              ? SpinKitCircle(color: Colors.black)
              : SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _pickImage(ImageSource.gallery);
                        print("image of picked image ${widget.image!}");
                      },
                      child:
                          _isLoading
                              ? _buildShimmerEffect()
                              : (widget.image != null
                                  ? Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: Image.file(
                                      widget.image!,
                                      height: 200,
                                      width: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : Icon(
                                    Icons.image,
                                    size: 200,
                                    color: Colors.grey,
                                  )),
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
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.image == null ||
                                  _resultAcne.isEmpty ||
                                  _resultType.isEmpty ||
                                  _resultTone.isEmpty ||
                                  _resultWrinkle.isEmpty ||
                                  _precautions.isEmpty)
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
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildField(
                                        "Acne Status",
                                        '${_resultAcne}',
                                        Colors.black,
                                      ),
                                      _buildFieldselct(
                                        "Skin Type",
                                        _resultType.isNotEmpty
                                            ? _resultType
                                            : null,
                                        _skinTypes,
                                        (newValue) {
                                          setState(() {
                                            _resultType = newValue!;
                                          });
                                        },
                                      ),
                                      _buildFieldselct(
                                        "Skin Tone",
                                        _resultTone.isNotEmpty
                                            ? _resultTone
                                            : null,
                                        _skinTones,
                                        (newValue) {
                                          setState(() {
                                            _resultTone = newValue!;
                                          });
                                        },
                                      ),
                                      _buildFieldselct(
                                        "Wrinkles",
                                        _resultWrinkle.isNotEmpty
                                            ? _resultWrinkle
                                            : null,
                                        _wrinkleLabels,
                                        (newValue) {
                                          setState(() {
                                            _resultWrinkle = newValue!;
                                          });
                                        },
                                      ),
                                      _buildField(
                                        "Precaution",
                                        '${_precautions}',
                                        Colors.black,
                                      ),

                                      SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: _saveData,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.deepPurple.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              height: 45,
                                              width: 100,
                                              child: Center(
                                                child: Text(
                                                  "Save",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    SizedBox(height: 70),
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
                    selectedValue.toString().isNotEmpty
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

  // Future<void> _saveData() async {
  //   try {
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User not logged in")));
  //       return;
  //     }
  //
  //     await FirebaseFirestore.instance
  //         .collection("users")
  //         .doc(user.uid)
  //         .collection("analysis")
  //         .doc("skin_analysis") // could use a timestamp if you want multiple entries
  //         .set({
  //       "acneStatus": _resultAcne,
  //       "skinType": _resultType,
  //       "skinTone": _resultTone,
  //       "wrinkles": _resultWrinkle,
  //       "precautions": _precautions,
  //       "imagePath": widget.image?.path ?? "",
  //       "timestamp": FieldValue.serverTimestamp(),
  //     });
  //
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Details Saved to Firebase!")));
  //   } catch (e) {
  //     print("Error saving data: $e");
  //   }
  // }
  // Future<void> _loadSavedData() async {
  //   try {
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user == null) {
  //       print("No user logged in.");
  //       return;
  //     }
  //
  //     final doc = await FirebaseFirestore.instance
  //         .collection("users")
  //         .doc(user.uid)
  //         .collection("analysis")
  //         .doc("skin_analysis")
  //         .get();
  //
  //     if (doc.exists) {
  //       final data = doc.data()!;
  //       setState(() {
  //         _resultAcne = data['acneStatus'] ?? "";
  //         _resultType = data['skinType'] ?? "";
  //         _resultTone = data['skinTone'] ?? "";
  //         _resultWrinkle = data['wrinkles'] ?? "";
  //         _precautions = data['precautions'] ?? "";
  //         _imagePath = data['imagePath'] ?? "";
  //
  //         if (_imagePath.isNotEmpty) {
  //           widget.image = File(_imagePath);
  //         }
  //         _isloading = false;
  //       });
  //
  //       print("Data loaded from Firebase.");
  //     } else {
  //       print("No skin analysis data found.");
  //       _isloading = false;
  //     }
  //   } catch (e) {
  //     print("Error loading data: $e");
  //     _isloading = false;
  //   }
  // }
}
