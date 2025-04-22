import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:src/screens/main_screen.dart';
import 'package:src/screens/watch_screen.dart';
import 'providers/provider.dart';


/*
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
*/


void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Asegurarse de que los widgets de Flutter esten inicializados

  // Configuracion Notificaciones
  /*
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  */

  runApp(
    ChangeNotifierProvider(
      create: (context) => MedicationProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const DeviceSelectorScreen(),
    );
  }
}

// Determina que pantalla mostrar dependiendo del tamaño del dispositivo
class DeviceSelectorScreen extends StatelessWidget {
  const DeviceSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isWatch = MediaQuery.of(context).size.shortestSide < 300;

    if (isWatch) {
      return WatchScreen();
    } else {
      return MainScreen();
    }
  }
}