import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'package:timezone/timezone.dart' as tz;
import '../providers/provider.dart';
import '../models/medication.dart';
import '../models/posology.dart';
import '../models/posologyMed.dart';
import '../models/intake.dart';
import '../main.dart';

class WatchScreen extends StatefulWidget {
  @override
  _WatchScreenState createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  @override
  void initState() {
    super.initState();
    // Usamos WidgetsBinding para asegurarnos de que el contexto esté listo
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Usamos Provider para obtener el proveedor adecuado y cargar los medicamentos
      await Provider.of<MedicationProvider>(context, listen: false)
          .fetchMedications(
              MedicationProvider().getPatientId); // Cargar medicamentos
      await Provider.of<MedicationProvider>(context, listen: false)
          .fetchAllPosologies(MedicationProvider().getPatientId); // Cargar posologías

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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true, // Extender el cuerpo detrás del AppBar
      appBar: AppBar( // Barra superior con la hora actual
        backgroundColor: Colors.transparent,
        elevation: 0, // Hacer la AppBar completamente transparente
        title: StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)),
          builder: (context, snapshot) {
            String currentTime = DateFormat('HH:mm').format(DateTime.now());
            return Text(
              currentTime,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            );
          },
        ),
        centerTitle: true,
        toolbarHeight: screenHeight * 0.1, // Establecer el margen superior a 0
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, medicationProvider, child) {
          if (medicationProvider.isLoading) {
            return Center(
                child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ));
          }
          if (medicationProvider.errorMessage.isNotEmpty) {
            return Center(child: Text(medicationProvider.errorMessage));
          }
          if (medicationProvider.allPosologies.isEmpty) {
            return Center(
              child: Text('No hay posologías disponibles'),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lista de Posologias
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: medicationProvider.allPosologies.length,
                    itemBuilder: (context, index) {
                      final posology = medicationProvider.allPosologies[index];
                      return PosologyTileW(
                          posology: posology); // Widget para cada medicamento
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PosologyTileW extends StatefulWidget {
  final PosologyMed posology;
  PosologyTileW({required this.posology});

  @override
  _PosologyTileState createState() => _PosologyTileState();
}

class _PosologyTileState extends State<PosologyTileW> {
  @override
  Widget build(BuildContext context) {
    // Hora actual
    final now = DateTime.now();
    final posologyTime = DateTime(
      now.year,
      now.month,
      now.day,
      widget.posology.hour,
      widget.posology.minute,
    );

    final isTime =
        now.isAfter(posologyTime) || now.isAtSameMomentAs(posologyTime);
    Color defaultColor = isTime ? Colors.red : Colors.white;

    // Mostrar notificación si es la hora de la posología

    return Expanded(
      child: Container(
        constraints: BoxConstraints( // Limites del contenedor
          minHeight: 50,
          maxHeight: 80,
          minWidth: double.infinity,
        ),
        child: InkWell( // Widget interactivo
          onTap: () async {
            if (!widget.posology.taken) {
              final date = DateTime.now();
              String year = date.year.toString();
              String month = date.month.toString().padLeft(2, '0');
              String day = date.day.toString().padLeft(2, '0');
              String hour = date.hour.toString().padLeft(2, '0');
              String minute = date.minute.toString().padLeft(2, '0');
              String takenDate = '$year-$month-${day}T$hour:$minute';

              final medicationProvider =
                  Provider.of<MedicationProvider>(context, listen: false);
              await medicationProvider.addIntake(
                  medicationProvider.getPatientId,
                  widget.posology.medicationId,
                  takenDate);

              if (medicationProvider.errorMessage.isNotEmpty) {
                print(medicationProvider.errorMessage);
                // Mostrar un SnackBar para notificar el error
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    Future.delayed(Duration(seconds: 2), () {
                      Navigator.of(context).pop(true);
                    });
                    return AlertDialog(
                      title: Text('Error'),
                      content: Text(medicationProvider.errorMessage),
                    );
                  },
                );
              } else { // OK
                widget.posology.taken = true;
                widget.posology.takenHour = '$hour:$minute';
              }

              (context as Element).markNeedsBuild();
            }
          },
          child: AnimatedContainer( // Contenedor animado
            duration: Duration(milliseconds: 300), // Duración de la animación
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8), 
            decoration: BoxDecoration(
              color: widget.posology.taken ? Colors.green : defaultColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow( // Sombra
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.posology.medicationName}',
                      style: TextStyle(
                          color: (isTime || widget.posology.taken)
                              ? Colors.white
                              : Colors.black,
                          fontSize: 12),
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: 4), // Espacio entre las filas
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.posology.dosage} mg',
                          style: TextStyle(
                              color: (isTime || widget.posology.taken)
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.posology.takenHour.isNotEmpty) // Hora a la que fue tomada
                          Text(
                            '${widget.posology.takenHour}',
                            style: TextStyle(
                                color: (isTime || widget.posology.taken)
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        Text(
                          '${widget.posology.hour}:${widget.posology.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                              color: (isTime || widget.posology.taken)
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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