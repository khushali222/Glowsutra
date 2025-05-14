import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'Screen/Authentication/LoginScreen/login.dart';
import 'Screen/Authentication/signupScreen/signup.dart';
import 'Screen/Splash_Screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    // MyApp(),
    DevicePreview(
      enabled: false,
      tools: [...DevicePreview.defaultTools],
      builder: (context) => MyApp(),
    ),
  );
}

// void main() {
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => ImageCacheProvider()), // Provide your ImageCacheProvider
//       ],
//       child: const MyApp(),
//     ),
//   );
// }
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Poppins'),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      //home: SignupScreen(),
    );
  }
}
