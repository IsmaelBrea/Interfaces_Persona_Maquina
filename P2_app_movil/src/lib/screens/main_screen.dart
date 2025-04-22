import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'package:timezone/timezone.dart' as tz;
import '../providers/provider.dart';
import 'info_screen.dart';
import 'treatment_screen.dart';
import '../main.dart';
import '../models/posologyMed.dart';


class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

   // Lista de pantallas para cada índice del BottomNavigationBar
  final List<Widget> _screens = [
    TreatmentScreen(),
    InfoScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Usamos WidgetsBinding para asegurarnos de que el contexto esté listo
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Usamos Provider para obtener el proveedor adecuado y cargar los medicamentos
      await Provider.of<MedicationProvider>(context, listen: false).fetchMedications(MedicationProvider().getPatientId);  // Cargar medicamentos
      await Provider.of<MedicationProvider>(context, listen: false).fetchAllPosologies(MedicationProvider().getPatientId);// Cargar posologías

      // Programar notificaciones para cada posología
      /*
      final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
      for (var posology in medicationProvider.allPosologies) {
        _scheduleNotification(posology); // Programar notificación para cada posología
      }   
      */ 
    });
  }

  // Función para programar una notificación
  /*
  void _scheduleNotification(PosologyMed posology) async {
    final now = DateTime.now();
    final posologyTime = DateTime(
      now.year,
      now.month,
      now.day,
      posology.hour,
      posology.minute,
    );

    // Programar la notificación 5 minutos antes de la hora de la posología
    final notificationTime = posologyTime.subtract(Duration(minutes: 5));

    if (notificationTime.isAfter(now)) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your_channel_id', // ID del canal de notificación
        'your_channel_name', // Nombre del canal de notificación
        channelDescription: 'your_channel_description', // Descripción del canal de notificación
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
      tz.initializeTimeZones();
      await flutterLocalNotificationsPlugin.zonedSchedule(
        posology.id, // ID único para la notificación
        'Hora de tomar tu medicación', // Título de la notificación
        'Quedan 5 minutos para tomar ${posology.medicationName}. Dosis: ${posology.dosage}', // Cuerpo de la notificación
        tz.TZDateTime.from(notificationTime, tz.local), // Hora de la notificación
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Barra superior con el titulo de la app
      appBar: AppBar(
        backgroundColor: Colors.green, // Color
        title: Text('MEDICATION APP'), // Título de la app
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), //Estilos
        centerTitle: true // Centrado
      ),

      // Barra de navegacion
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem( // Elememto1
            icon: Icon(Icons.medical_services), // Icono1
            label: 'Tratamiento', // Titulo1
          ),
          BottomNavigationBarItem( // Elemento2
            icon: Icon(Icons.info), // Icono2
            label: 'Información', //Titulo2
          ),
        ],
        currentIndex: _currentIndex, // Idice de la ventana seleccionada
        selectedItemColor: Colors.green, // Color
        onTap: _onTabTapped,
      ),

      body: _screens[_currentIndex],
    );
  }
}