import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'Screen/Splash_Screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // MyApp(),
    DevicePreview(
      enabled: true,
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
    return MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen());
  }
}
