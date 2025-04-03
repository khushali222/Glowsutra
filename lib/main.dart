import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:glow_sutra/Screen/home.dart';

import 'package:provider/provider.dart';

import 'Serviece/notification_service.dart';

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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomePage());
  }
}
