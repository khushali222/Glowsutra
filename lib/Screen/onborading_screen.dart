import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utiles/onboarding_content.dart';
import '../utiles/size_config.dart';
import 'home.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _controller;

  @override
  void initState() {
    _controller = PageController();
    super.initState();
  }

  int _currentPage = 0;
  List colors = const [Color(0xffDAD3C8), Color(0xffFFE5DE), Color(0xffDCF6E6)];

  AnimatedContainer _buildDots({int? index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(50)),
        color: Color(0xFF000000),
      ),
      margin: const EdgeInsets.only(right: 5),
      height: 10,
      curve: Curves.easeIn,
      width: _currentPage == index ? 20 : 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double width = SizeConfig.screenW!;
    double height = SizeConfig.screenH!;

    return Scaffold(
      backgroundColor: colors[_currentPage],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: PageView.builder(
                physics: const BouncingScrollPhysics(),
                controller: _controller,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: contents.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Expanded(child: Image.asset(contents[i].image)),
                        SizedBox(height: (height >= 840) ? 60 : 30),
                        Text(
                          contents[i].title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "Mulish",
                            fontWeight: FontWeight.w600,
                            fontSize: (width <= 550) ? 30 : 35,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          contents[i].desc,
                          style: TextStyle(
                            fontFamily: "Mulish",
                            fontWeight: FontWeight.w300,
                            fontSize: (width <= 550) ? 17 : 25,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      contents.length,
                      (int index) => _buildDots(index: index),
                    ),
                  ),
                  _currentPage + 1 == contents.length
                      ? Padding(
                        padding: const EdgeInsets.all(30),
                        child: ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('onboarding_complete', true);
                            final now = DateTime.now();
                            await prefs.setInt('water_glasses', 0);
                            await prefs.setString(
                              'last_updated',
                              now.toIso8601String(),
                            );
                            print(
                              "Resetting water glasses count because a new day has started.",
                            );
                            final deviceId =
                                prefs.getString('device_id') ??
                                "unknown_device_id";
                            print("Device ID splash: $deviceId");

                            await FirebaseFirestore.instance
                                .collection("User")
                                .doc(
                                  "fireid",
                                ) // Replace with actual user doc if needed
                                .collection("waterGlasess")
                                .doc(deviceId)
                                .set({
                                  'glasscount': 0,
                                  'lastUpdated': Timestamp.now(),
                                },SetOptions(merge: true)
                                );
                            print("Firebase glasscount reset to 0. from onbordingscreen ");
                            // This will clear the OnboardingScreen from the navigation stack
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(),
                              ),
                              (route) => false, // Remove all previous screens
                            );
                          },
                          child: const Text("START"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding:
                                (width <= 550)
                                    ? const EdgeInsets.symmetric(
                                      horizontal: 100,
                                      vertical: 20,
                                    )
                                    : EdgeInsets.symmetric(
                                      horizontal: width * 0.2,
                                      vertical: 25,
                                    ),
                            textStyle: TextStyle(
                              fontSize: (width <= 550) ? 13 : 17,
                            ),
                          ),
                        ),
                      )
                      : Padding(
                        padding: const EdgeInsets.all(30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                _controller.jumpToPage(2);
                              },
                              child: const Text(
                                "SKIP",
                                style: TextStyle(color: Colors.black),
                              ),
                              style: TextButton.styleFrom(
                                elevation: 0,
                                textStyle: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: (width <= 550) ? 13 : 17,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _controller.nextPage(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeIn,
                                );
                              },
                              child: const Text("NEXT"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                elevation: 0,
                                padding:
                                    (width <= 550)
                                        ? const EdgeInsets.symmetric(
                                          horizontal: 30,
                                          vertical: 20,
                                        )
                                        : const EdgeInsets.symmetric(
                                          horizontal: 30,
                                          vertical: 25,
                                        ),
                                textStyle: TextStyle(
                                  fontSize: (width <= 550) ? 13 : 17,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
