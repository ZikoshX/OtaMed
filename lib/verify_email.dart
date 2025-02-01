import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/wrapper.dart';
import 'package:get/get.dart';


class Verifyemail extends StatefulWidget {
  const Verifyemail({super.key});

  @override
  State<Verifyemail> createState() => _VerifyemailState();
}

class _VerifyemailState extends State<Verifyemail> {
  @override
  void initState() {
    sendverifylink();
    super.initState();
  }

  sendverifylink() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.sendEmailVerification().then(
      (value) => {
        Get.snackbar(
          'Link sent',
          'A link has been send to your email',
          margin: EdgeInsets.all(20),
          snackPosition: SnackPosition.BOTTOM,
        ),
      },
    );
  }

  reload() async {
    await FirebaseAuth.instance.currentUser!.reload().then(
      (value) => {Get.offAll(Wrapper())}
    );
  }
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
