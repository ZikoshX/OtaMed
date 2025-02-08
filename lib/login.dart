import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Services/authentication.dart';
import 'package:flutter_application_1/forgotpassword.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/signup.dart';
import 'package:flutter_application_1/widget/button.dart';
import 'package:flutter_application_1/widget/snackbar.dart';
import 'package:flutter_application_1/widget/text_field.dart';
import 'dart:io';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  final auth = AuthServices();

  String emailError = '';
  String passwordError = '';
  String inError = "";
  bool isLoading = false;
  bool isAppleLoading = false;

  @override
  void dispose() {
    super.dispose();
    email.dispose();
    password.dispose();
  }

  void loginUsers() async {
    setState(() {
      isLoading = true;
      emailError = "";
      passwordError = "";
      inError = "";
    });

    try {
      if (email.text.trim().isEmpty || password.text.trim().isEmpty) {
        setState(() {
          if (email.text.trim().isEmpty && password.text.trim().isEmpty) {
            emailError = "Please fill in all the fields.";
          } else if (email.text.trim().isEmpty) {
            emailError = "Please enter your email address.";
          } else if (password.text.trim().isEmpty) {
            passwordError = "Please enter your password.";
          }
        });
        return;
      }
      String res = await AuthServices().loginUser(
        email: email.text.trim(),
        password: password.text.trim(),
      );
      if (!mounted) return;

      if (res == 'success') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        setState(() {
          if (res.contains('email')) {
            emailError = res;
          } else if (res.contains('password')) {
            passwordError = res;
          } else if (res.contains('Incorrect')) {
            inError = res;
          } else {
            emailError = res;
          }
        });
      }
    } catch (e) {
      showSnackBar(context, "Something went wrong. Please try again later.");
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
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor:  colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
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
                    SizedBox(height: height / 30),
                    Center(
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Signup(),
                              ),
                            );
                          },
                          child: Text(
                            "Sign up",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Column(
                      children: [
                        TextFieldInput(
                          textEditingController: email,
                          hintText: "Email",
                          icon: Icons.email,
                          iconColor: colorScheme.onSurface,
                          onChanged: (value) {
                            setState(() {
                              emailError = "";
                            });
                          },
                        ),

                        if (emailError.isNotEmpty)
                          Row(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 30.0),
                                    child: Text(
                                      emailError,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Column(
                      children: [
                        TextFieldInput(
                          textEditingController: password,
                          hintText: "Password",
                          isPass: true,
                          icon: Icons.lock,
                          iconColor: colorScheme.onSurface,
                          onChanged: (value) {
                            setState(() {
                              passwordError = "";
                            });
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 30.0),
                                  child: Text(
                                    passwordError,
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPassword(),
                              ),
                            );
                          },
                          child: Text(
                            "Forgot password?",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    MyButton(
                      onTab: loginUsers,
                      text: isLoading ? "Loading..." : "Log in",
                      color: colorScheme.primary, 
                    ),
                     Text("──── or ────",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: Colors.grey),
                     textAlign: TextAlign.center,),
                     const SizedBox(height: 10),
                    Column(                    
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    isLoading
        ? const CircularProgressIndicator()
        : GestureDetector(
            onTap: () async {
              setState(() {
                isLoading = true;
              });
              UserCredential? userCredential = await AuthServices().signinWithGoogle();

              if (userCredential != null) {
                Navigator.pushReplacement(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              }
              setState(() {
                isLoading = false;
              });
            },
            
            child: Container(
              width: 250,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: colorScheme.onSurface),
              ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                 children: [
              Image.asset("images/googleit.jpg", height: 24), 
              SizedBox(width: 10),
              Text(
                "Sign in with Google",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,color: colorScheme.onSurface,),
              ),
            ],
          ),
                
              ),
            ),
    const SizedBox(height: 10),
    if (Platform.isIOS)
      isAppleLoading
          ? const CircularProgressIndicator()
          : GestureDetector(
              onTap: () async {
                setState(() {
                  isLoading = true;
                });
                UserCredential? userCredential = await AuthServices().signInWithApple();
                if (userCredential != null) {
                  Navigator.pushReplacement(
                     // ignore: use_build_context_synchronously
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                }
                setState(() {
                  isLoading = false;
                });
              },
               child: Container(
              width: 250,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: colorScheme.onSurface),
              ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                 children: [
              Image.asset("images/id.jpeg", height: 24), 
              SizedBox(width: 10),
              Text(
                "Sign in with Apple ID",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,color: colorScheme.onSurface,),
              ),
            ],
          ),
                
              ),
            ),
           ],
        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
