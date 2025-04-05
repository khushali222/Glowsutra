class OnboardingContents {
  final String title;
  final String image;
  final String desc;

  OnboardingContents({
    required this.title,
    required this.image,
    required this.desc,
  });
}

List<OnboardingContents> contents = [
  OnboardingContents(
    title: "Track Your skin and get the result",
    image: "assets/images/image1.png",
    desc: "Remember to keep track of your skin accomplishments.",
  ),
  OnboardingContents(
    title: "Glow with Confidence",
    image: "assets/images/image2.png",
    desc:
    "Discover personalized skincare routines and expert tips to keep your skin healthy, radiant, and refreshed every day.",
  ),
  OnboardingContents(
    title: "Stay Hydrated, Stay Glowing",
    image: "assets/images/image3.png",
    desc:
    "Get smart reminders to drink water regularly — because healthy, hydrated skin starts from within.",
  ),
];