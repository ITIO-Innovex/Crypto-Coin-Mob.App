import 'package:coincraze/Constants/Colors.dart';
import 'package:flutter/material.dart';

class ColorCodes extends StatelessWidget {
  const ColorCodes({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Black Theme Demo',
      home: Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome Bhai!',
                  style: TextStyle(
                    color: AppColors.snowWhite,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Yeh tera black theme wala app hai!',
                  style: TextStyle(
                    color: AppColors.charcoal,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.slateBlue,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () {},
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}