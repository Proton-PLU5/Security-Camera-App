
import 'package:camera_application/data/TSizes.dart';
import 'package:camera_application/data/TText.dart';
import 'package:camera_application/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  FlutterSecureStorage secureStorage = FlutterSecureStorage();

  String username = '';
  String password = '';

  void onLoginPressed() {
    // Handle login logic here
    secureStorage.write(key: 'username', value: username);
    secureStorage.write(key: 'password', value: password);

    // Navigate to the home page after successful login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 100.0,
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // LOGO
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security, size: 100, color: Colors.blue),
                  Text(TText.loginTitle, style: TextStyle(
                    fontSize: TSizes.headingFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  )),
                  SizedBox(height: 16.0),
                  Text(TText.loginPrompt, style: TextStyle(
                    fontSize: TSizes.regularFontSize,
                    color: Colors.grey[600],
                  )),
                  SizedBox(height: 32.0),
                ]
              ),
              Form(child: Column(
                  children: [
                    /// USERNAME
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Iconsax.user),
                        labelText: TText.loginUsernameHint,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          username = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),

                    /// PASSWORD
                    TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Iconsax.password_check),
                        labelText: TText.loginPasswordHint,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          password = value;
                        });
                      },
                    ),
                    const SizedBox(height: 64.0),

                    /// LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle login logic here
                          onLoginPressed();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(TText.loginButtonText),
                      ),
                    )
                  ]
                )
              )
            ],
          ),
        )
      )
    );
  }
  
}

