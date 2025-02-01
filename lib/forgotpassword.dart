import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_application_1/widget/text_field.dart';
import 'package:flutter_application_1/widget/button.dart'; 

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
   State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  resetPassword() async {
    if (emailController.text.isEmpty) {
      Get.snackbar("Error", "Please enter your email",
          snackPosition: SnackPosition.BOTTOM, margin: EdgeInsets.all(20));
      return;
    }

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());
      Get.snackbar("Success", "Password reset link sent to your email",
          snackPosition: SnackPosition.BOTTOM, margin: EdgeInsets.all(20));
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM, margin: EdgeInsets.all(20));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'images/logo.webp',
                        height: 200,
                        width: 200,
                      ),
                    ),
            const SizedBox(height: 40,),        
            TextFieldInput(
              textEditingController: emailController,
              hintText: "Email",
              icon: Icons.email,
            ),
            SizedBox(
              width: 120,
              height: 90, 
              child: MyButton(
              onTab: resetPassword,
                   text: isLoading ? "Loading..." : "Send",
               ),
            ),
                  ],
        ),
      ),
    );
  }
}
