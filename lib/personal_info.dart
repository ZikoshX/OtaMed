import 'dart:io';
import 'package:country_picker/country_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:open_file/open_file.dart';

var logger = Logger();

class PersonalInfo extends StatefulWidget {
  const PersonalInfo({super.key});

  @override
  State<PersonalInfo> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfo> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  String userId = FirebaseAuth.instance.currentUser!.uid;
  Country? selectedCountry; 

  bool isEditingName = false;
  bool isEditingEmail = false;
  bool isEditingCountry = false;
  bool isLoading = false;
  String username = "";
  String email = "";
  File? selectedFile;
  String? imageUrl;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchUserDatas();
  }

  void fetchUserDatas() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        var userData =
            await FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .get();

        if (userData.exists) {
          setState(() {
            username = userData["name"] ?? "Unknown User";
            nameController.text = username;
            email = userData["email"] ?? "Unknown Email";
            emailController.text = email;
            imageUrl = userData["profileImage"] ?? "Unknown Image";
          });
        } else {
          logger.w("User data does not exist in Firestore");
        }
      } catch (e) {
        logger.w("Error fetching user data: $e");
      }
    } else {
      logger.w("No user is logged in");
    }
  }

  void updateUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({"name": nameController.text});
        setState(() {
          username = nameController.text;
          isEditingName = false;
        });
      } catch (e) {
        logger.w("Error updating name: $e");
      }
    }
  }

  Future<void> pickImage() async {
    try {
      XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        await uploadImageToFirebase(File(pickedFile.path));
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to pick image: $e"),
        ),
      );
    }
  }

  Future<void> uploadImageToFirebase(File image) async {
    setState(() {
       isLoading = true;
    });
   
    try {
      Reference reference = FirebaseStorage.instance.ref().child(
        "images/${DateTime.now().microsecondsSinceEpoch}.png",
      );
      await reference.putFile(image).whenComplete(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            content: Text("Upload successfully"),
          ),
        );
      });
      imageUrl = await reference.getDownloadURL();
       await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'profileImage': imageUrl,  
    }, SetOptions(merge: true)); 

    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to pick image: $e"),
        ),
      );
    }
    setState(() {
       isLoading = false;
    });
  }

  Future<void> pickAndOpenFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;
    await OpenFile.open(file.path!);
    setState(() {
      selectedFile = File(file.path!);
    });
    // ignore: use_build_context_synchronously
    Navigator.pop(context, File(file.path!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Info"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
  radius: 70,
  backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
      ? NetworkImage(imageUrl!)  
      : null,  
  child: imageUrl == null 
      ? const Icon(
          Icons.person,
          size: 70,
          color: Colors.grey,
        )
      : ClipOval(
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 140,
              height: 140,
              child: Image.network(
                imageUrl!,  
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child;  
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    ); 
                  }
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    size: 70,
                    color: Colors.grey,
                  );  
                },
              ),
            ),
          ),
        ),
),

                if(isLoading) 
                const Positioned(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white,),
                  )),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: IconButton(
                      onPressed: pickImage,
                      icon: Icon(Icons.add_a_photo, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            GestureDetector(
              onTap: () {
                setState(() {
                  isEditingName = !isEditingName;
                });
              },
              child: _buildEditableField(
                label: "Full Name",
                controller: nameController,
                isEditing: isEditingName,
                onEditTap: () {
                  setState(() {
                    isEditingName = !isEditingName;
                  });
                if (!isEditingName) {
                updateUserName();
              }
                },
              ),
            ),

            const SizedBox(height: 20),
            _buildEditableField(
              label: "Email",
              controller: emailController,
              isEditing: isEditingEmail,
              onEditTap: () {
                setState(() {
                  isEditingEmail = !isEditingEmail;
                });
              },
            ),
            const SizedBox(height: 20),
             Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                showCountryPicker(
                  context: context,
                  showPhoneCode: true, 
                  onSelect: (Country country) {
                    setState(() {
                      selectedCountry = country;
                    });
                  },
                );
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      selectedCountry != null
                          ? selectedCountry!.name
                          : 'Select a Country',
                      style: TextStyle(fontSize: 18),
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
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.black)),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: isEditing,
                decoration: InputDecoration(
                  border: isEditing ? OutlineInputBorder() : InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: Icon(
                isEditing ? Icons.check : Icons.edit,
                color: Colors.blueAccent,
              ),
              onPressed: onEditTap,
            ),
          ],
        ),
      ],
    );
  }
}
