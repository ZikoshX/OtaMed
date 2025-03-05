import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  String message = '';
  Color messageColor = Colors.red;

  resetPassword() async {
    setState(() {
      message = '';
      isLoading = true;
    });

    String email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        message = "Please enter your email";
        messageColor = Colors.red;
        isLoading = false;
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        isLoading = true;
        message = "Password reset link sent to your email";
        messageColor = Colors.green;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        setState(() {
          message = "Invalid email format";
          messageColor = Colors.red;
        });
      } else {
        setState(() {
          message = "An error occurred. Try again.";
          messageColor = Colors.red;
        });
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('images/logoapp.png', height: 200, width: 200),

            const SizedBox(height: 40),
            TextFieldInput(
              textEditingController: emailController,
              hintText: "Email",
              icon: Icons.email,
              iconColor: colorScheme.onSurface,
            ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 30.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message,
                    style: TextStyle(color: messageColor, fontSize: 15),
                  ),
                ),
              ),
            SizedBox(
              width: 120,
              height: 90,
              child: MyButton(
                onTab: resetPassword,
                text: isLoading ? "Loading..." : "Send",
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
