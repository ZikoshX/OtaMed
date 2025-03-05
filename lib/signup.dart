import 'package:flutter/material.dart';
import 'package:flutter_application_1/Services/authentication.dart';
import 'package:flutter_application_1/login.dart';
import 'package:flutter_application_1/widget/button.dart';
import 'package:flutter_application_1/widget/snackbar.dart';
import 'package:flutter_application_1/widget/text_field.dart';
//import 'package:flutter_application_1/personal_info.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();

 

  bool isLoading = false;
  String emailError = '';
  String passwordError = '';
  String nameError = '';
  String successMessage = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void signUp() async {
    try {
      String res = await AuthServices().signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(), 
      );
      if (!mounted) return;

      if (res == 'success') {
        setState(() {
           successMessage = "Registration successful! Redirecting to login...";
          isLoading = true;
        });
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Login()),
        );
      } else {
        setState(() {
          if (res.contains('already in use') || res.contains('email already exists')) {
          emailError = "This email is already registered. Please log in.";
            }
          if (res.contains('email')) {
            emailError = res;
          } else if (res.contains('Please fill in all the fields')) {
            passwordError = res;
          } else if (res.contains('password')) {
            passwordError = res;
          } else {
            showSnackBar(context, "Registration failed. Please try again.");
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
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'images/logoapp.png',
                        height: 260,
                        width: 260,
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: const Text(
                        "Sign Up",
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
                          "Already have an account?",
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Login()),
                            );
                          },
                          child: Text(
                            " Login",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    
                    TextFieldInput(
                      textEditingController: nameController,
                      hintText: "Full Name",
                      icon: Icons.person,
                      iconColor: colorScheme.onSurface,
                      onChanged: (value) {
                        setState(() {
                          nameError = "";
                        });
                      },
                    ),

                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                             TextFieldInput(
                      textEditingController: emailController,
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
                    Padding(
                     padding: const EdgeInsets.only(left: 30.0), 
                     child: Align(
                     alignment: Alignment.centerLeft, 
                     child: Text(
                        emailError,
                        style: TextStyle(color: Colors.red, fontSize: 15),
          ),
        ),
      ),
  ],
),
                   
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                             TextFieldInput(
                      textEditingController: passwordController,
                      hintText: "Password",
                      icon: Icons.lock,
                      iconColor: colorScheme.onSurface,
                      onChanged: (value) {
                        setState(() {
                          passwordError = "";
                        });
                      },
                    ),
                  if (passwordError.isNotEmpty)
                    Padding(
                     padding: const EdgeInsets.only(left: 30.0), 
                     child: Align(
                     alignment: Alignment.centerLeft, 
                     child: Text(
                        passwordError,
                        style: TextStyle(color: Colors.red, fontSize: 15),
          ),
        ),
      ),
  ],
),
                  if (successMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          successMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                   
                    SizedBox(height: 20),
                    MyButton(onTab: signUp, 
                     text: isLoading ? "Signing Up..." : "Sign Up",
                    color: colorScheme.primary, ),
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
