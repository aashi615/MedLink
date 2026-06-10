import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medlink/Homepage.dart';
import 'Varify.dart';
import 'loginScreen.dart';

class Wrapper extends StatefulWidget {
  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Firebase Error: ${snapshot.error}");
            return const Center(child: Text("An error occurred. Please restart the app."));
          }

          if (!isNavigating) {
            isNavigating = true;

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final user = snapshot.data;

              if (user != null) {
                if (user.emailVerified) {
                  Get.offAll(() => HomePage()); // 🔄 roomCode removed
                } else {
                  Get.offAll(() => Varify());
                }
              } else {
                Get.offAll(() => loginScreen());
              }
            });
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
