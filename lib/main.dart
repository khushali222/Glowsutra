import 'package:flutter/material.dart';

import 'package:glow_sutra/test.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp(

  ));
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
    return MaterialApp(home: SkinClassifierScreen());
  }
}
