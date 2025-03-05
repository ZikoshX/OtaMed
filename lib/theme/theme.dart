import 'package:flutter/material.dart';


class MyThemes {
  static final darkTheme = ThemeData(
    scaffoldBackgroundColor: Colors.black,
    iconTheme: const IconThemeData(color: Colors.white),
    cardColor: Colors.black,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue, 
      secondary: Colors.orange, 
      surface: Colors.black, 
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black, 
      titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
    ),
    textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white)
    ),
     dropdownMenuTheme: DropdownMenuThemeData(
    textStyle: TextStyle(color: Colors.white),
    menuStyle: MenuStyle(
      backgroundColor: WidgetStateProperty.all(Colors.grey[900]),
    ),
  ),
  );
  static final lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    iconTheme: const IconThemeData(color: Colors.black),
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue, 
      secondary: Colors.orange, 
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
       backgroundColor: Colors.white, 
      iconTheme: IconThemeData(
        color: Colors.black,
      ),
      titleTextStyle: TextStyle(color:Colors.black, fontWeight: FontWeight.bold, fontSize: 20)
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black )
    ),
     dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(color: Colors.black),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
      ),
    ),
    );
}
