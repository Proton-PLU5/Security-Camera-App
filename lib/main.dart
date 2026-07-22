import 'package:camera_application/data/TText.dart';
import 'package:camera_application/pages/home.dart';
import 'package:camera_application/models/camera.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(CameraAdapter());
  await Hive.openBox<Camera>('favoriteCameras');
  await Hive.openBox<Camera>('cameras');

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: TText.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}