import 'dart:io';
//import 'dart:typed_data';
import 'package:country_picker/country_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:cached_network_image/cached_network_image.dart';
//import 'package:image/image.dart' as img;

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
            if (userData["country"] != null) {
              selectedCountry = CountryParser.parse(userData["country"]!);
            }
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

  void saveSelectedCountry(Country country) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({"country": country.name});

        setState(() {
          selectedCountry = country;
        });

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Country updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        logger.w("Error updating country: $e");
      }
    }
  }

  void updateCountry(Country country) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({"country": country.countryCode});
        setState(() {
          selectedCountry = country;
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Country updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        logger.w("Error updating country: $e");
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
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      String? oldImageUrl;
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('profileImage')) {
          oldImageUrl = userData['profileImage'];
        }
      }
      Reference reference = FirebaseStorage.instance.ref().child(
        "images/${DateTime.now().microsecondsSinceEpoch}.png",
      );
      await reference.putFile(image);

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
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        try {
          Reference oldImageRef = FirebaseStorage.instance.refFromURL(
            oldImageUrl,
          );
          await oldImageRef.delete();
          logger.w("Old image deleted successfully.");
        } catch (e) {
          logger.w("Error deleting old image: $e");
        }
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

  Future<void> deleteOldImageFromFirebase() async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (userDoc.exists && userDoc.data() != null) {
        String? oldImageUrl = userDoc.get('profileImage');
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          Reference oldImageRef = FirebaseStorage.instance.refFromURL(
            oldImageUrl,
          );
          await oldImageRef.delete();
        }
      }
    } catch (e) {
      logger.w("No old image to delete: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Personal Info", style: theme.appBarTheme.titleTextStyle),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      imageUrl != null && imageUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(imageUrl!)
                              as ImageProvider
                          : null,
                  child:
                      imageUrl == null
                          ? const Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.grey,
                          )
                          : ClipOval(
                            child: Image.network(
                              imageUrl!,
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                );
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

                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      onPressed: pickImage,
                      icon: const Icon(
                        Icons.add_a_photo,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildEditableField(
                          controller: nameController,
                          isEditing: isEditingName,
                          onEditTap: () {
                            setState(() {
                              isEditingName = !isEditingName;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.email,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildEditableField(
                          controller: emailController,
                          isEditing: isEditingEmail,
                          onEditTap: () {
                            setState(() {
                              isEditingEmail = !isEditingEmail;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showCountryPicker(
                              context: context,
                              showPhoneCode: true,
                              countryListTheme: CountryListThemeData(
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                textStyle:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                              onSelect: (Country country) {
                                setState(() {
                                  selectedCountry = country;
                                });
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  selectedCountry != null
                                      ? selectedCountry!.name
                                      : 'Select a Country',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      Colors.white,
                ),
                enabled: isEditing,
                decoration: InputDecoration(
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                isEditing ? Icons.check : Icons.edit_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: onEditTap,
            ),
          ],
        ),
      ],
    );
  }
}
