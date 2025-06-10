// Future<void> _addReminder() async {
//   final pickedTime = await showTimePicker(
//     context: context,
//     initialTime: TimeOfDay.now(),
//   );
//   if (pickedTime != null) {
//     final scheduledDateTime = DateTime(
//       _selectedDate.year,
//       _selectedDate.month,
//       _selectedDate.day,
//       pickedTime.hour,
//       pickedTime.minute,
//     );
//
//     TextEditingController controller = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text("Add Reminder"),
//         content: TextField(
//           controller: controller,
//           decoration: InputDecoration(hintText: "Enter reminder"),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () async {
//               String reminderText = controller.text;
//               if (reminderText.isNotEmpty) {
//                 setState(() {
//                   _reminders[_selectedDate] ??= [];
//                   _reminders[_selectedDate]!.add({
//                     'text': reminderText,
//                     'time': scheduledDateTime.toIso8601String(),
//                   });
//                 });
//
//                 _scheduleNotification(reminderText, scheduledDateTime);
//                 _saveReminders();
//
//                 try {
//                   final userId = FirebaseAuth.instance.currentUser?.uid ?? "guest";
//
//                   await FirebaseFirestore.instance
//                       .collection("User")
//                       .doc("fireid") // Replace with dynamic if needed
//                       .collection("reminders")
//                       .add({
//                     "userId": userId,
//                     "reminderText": reminderText,
//                     "scheduledTime": scheduledDateTime.toIso8601String(),
//                     "createdAt": Timestamp.now(),
//                   });
//                 } catch (e) {
//                   print("Error saving reminder to Firestore: $e");
//                 }
//
//                 Navigator.pop(context);
//               }
//             },
//             child: Text("Save"),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// pedometer.listen((event) async {
// final now = DateTime.now();
//
// // Get the last saved steps and lastUpdated timestamp if needed (fetch once or cache)
//
// // Calculate totalSteps...
//
// final calories = totalSteps * userWeight * 0.0005;
//
// await docRef.set({
// "steps": totalSteps,
// "calories": calories,
// "lastUpdated": Timestamp.fromDate(now),
// "timezone": tz.local.name,
// }, SetOptions(merge: true));
//
// print("Updated steps for user $userId: $totalSteps");
// });

// final todayDoc = DateFormat('yyyy-MM-dd').format(DateTime.now());
//
// final docRef = FirebaseFirestore.instance
//     .collection("User")
//     .doc(userId)
//     .collection("stepCounter")
//     .doc(todayDoc);

// FirebaseFirestore.instance
//     .collection("User")
// .doc(userId)   // <-- change from "fireid" to userId here
//     .collection("waterGlasess")
//     .doc("dailyRecord") // or any fixed doc name
//     .set({
// "glasscount": currentGlasses,
// "timezone": currentTimeZone,
// "lastUpdated": Timestamp.now(),
// });

//for stepcounter

// final userId = FirebaseAuth.instance.currentUser?.uid;
//
// if (userId == null) {
// print("No user logged in.");
// return;
// }
//
// final docRef = FirebaseFirestore.instance
//     .collection("User")
//     .doc(userId) // ✅ Use userId directly — not "fireid"
//     .collection("stepCounter")
//     .doc("stepData"); // ✅ fixed document name
//
// // Fetch last saved steps and lastUpdated timestamp
// DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();
// int lastSavedSteps = snapshot.data()?['steps'] ?? 0;
// Timestamp? lastUpdatedTimestamp = snapshot.data()?['lastUpdated'];
//
// int? initialSensorStep;
//
// pedometer.listen((event) async {
// final now = DateTime.now();
//
// // Check for new day
// DateTime lastUpdatedDate = lastUpdatedTimestamp?.toDate() ?? DateTime(2000);
// bool isNewDay =
// !(lastUpdatedDate.year == now.year &&
// lastUpdatedDate.month == now.month &&
// lastUpdatedDate.day == now.day);
//
// if (isNewDay) {
// lastSavedSteps = 0;
// initialSensorStep = event.steps;
// lastUpdatedTimestamp = Timestamp.fromDate(now);
//
// await docRef.set({
// "steps": 0,
// "calories": 0.0,
// "lastUpdated": lastUpdatedTimestamp,
// "timezone": tz.local.name,
// }, SetOptions(merge: true));
//
// print("Step count reset for new day.");
// }
//
// // Set baseline if not set
// if (initialSensorStep == null) {
// initialSensorStep = event.steps;
// }
//
// int stepsSinceReboot = event.steps - initialSensorStep!;
// if (stepsSinceReboot < 0) stepsSinceReboot = 0;
//
// int totalSteps = lastSavedSteps + stepsSinceReboot;
//
// // Get user weight
// final userDoc = await FirebaseFirestore.instance
//     .collection('User')
//     .doc(userId)
//     .get();
//
// final weightStr = userDoc.data()?['weight']?.toString() ?? '70';
// final weight = double.tryParse(weightStr) ?? 70.0;
// final calories = totalSteps * weight * 0.0005;
//
// // Update Firestore
// await docRef.set({
// "steps": totalSteps,
// "lastUpdated": Timestamp.fromDate(now),
// "calories": calories,
// "weight": weight,
// "timezone": tz.local.name,
// }, SetOptions(merge: true));
//
// if (service is AndroidServiceInstance) {
// service.setForegroundNotificationInfo(
// title: "Step Counter Running",
// content: "Steps: $totalSteps",
// );
// }
// });



