import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions; // Optional actions like icons/buttons

  const CustomAppBar({Key? key, required this.title, this.actions})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:
          Colors.transparent, // Make background transparent for gradient
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade100,
              Colors.deepPurple.shade200,
            ], // Gradient colors
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 8.0,
              color: Colors.black.withOpacity(0.5),
              offset: Offset(0, 0),
            ),
          ],
        ),
      ),
      centerTitle: true, // Centering the title
      actions: actions,
      elevation: 8, // Add some elevation for depth
      // leading: Builder(
      //   builder: (context) {
      //     return IconButton(
      //       icon: Icon(Icons.menu, color: Colors.black),
      //       onPressed: () {
      //         Scaffold.of(
      //           context,
      //         ).openDrawer(); // Open drawer when icon is pressed
      //       },
      //     );
      //   },
      // ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
