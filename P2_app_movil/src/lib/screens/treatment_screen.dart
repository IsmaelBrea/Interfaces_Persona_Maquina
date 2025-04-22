import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/provider.dart';
import '../models/posologyMed.dart';


class TreatmentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MedicationProvider>(
        builder: (context, medicationProvider, child) {
          if (medicationProvider.isLoading) { // Cargando
            return Center(
                child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ));
          }
          if (medicationProvider.errorMessage.isNotEmpty) { // Mensaje de error
            return Center(child: Text(medicationProvider.errorMessage));
          }
          if (medicationProvider.allPosologies.isEmpty) { // No hay posologías
            return Center(
              child: Text('No hay posologías disponibles'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: medicationProvider.allPosologies.length,
                  itemBuilder: (context, index) {
                    final posology = medicationProvider.allPosologies[index];
                    return PosologyTile( // Widget para cada posología
                      posology: posology,
                      medicationProvider: medicationProvider,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PosologyTile extends StatelessWidget {
  final PosologyMed posology;
  final MedicationProvider medicationProvider;

  PosologyTile({required this.posology, required this.medicationProvider});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final posologyTime = DateTime(
      now.year,
      now.month,
      now.day,
      posology.hour,
      posology.minute,
    );

    final isTime =
        now.isAfter(posologyTime) || now.isAtSameMomentAs(posologyTime);
    Color tileColor = isTime ? Colors.red : Colors.white;

    return Container(
      constraints: BoxConstraints( // Limites del contenedor
        minHeight: 90,
        maxHeight: 140,
        minWidth: double.infinity,
      ),
      child: InkWell( // Widget interactivo
        onTap: () async { // Acción al hacer tap
          if (!posology.taken) {
            final date = DateTime.now();
            String year = date.year.toString();
            String month = date.month.toString().padLeft(2, '0');
            String day = date.day.toString().padLeft(2, '0');
            String hour = date.hour.toString().padLeft(2, '0');
            String minute = date.minute.toString().padLeft(2, '0');
            String takenDate = '$year-$month-${day}T$hour:$minute';

            await medicationProvider.addIntake(medicationProvider.getPatientId, posology.medicationId, takenDate);

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
              posology.taken = true;
              posology.takenHour = '$hour:$minute';
            }
            (context as Element).markNeedsBuild();
          }
        },
        child: AnimatedContainer( // Contenedor animado
          duration: Duration(milliseconds: 300), // Duración de la animación
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: posology.taken ? Colors.green : tileColor, // Color del contenedor
            borderRadius: BorderRadius.circular(16),
            boxShadow: [ // Sombra
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            posology.medicationName,
                            style: TextStyle(
                              color: (isTime || posology.taken)
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                      Text(
                        '${posology.dosage} mg',
                        style: TextStyle(
                          color: (isTime || posology.taken)
                              ? Colors.white
                              : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hora de la Toma: ${posology.hour.toString().padLeft(2, '0')}:${posology.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: (isTime || posology.taken)
                              ? Colors.white
                              : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (posology.takenHour.isNotEmpty) // Hora a la que fue tomada
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Tomada a las: ',
                                style: TextStyle(
                                  color: (isTime || posology.taken)
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: posology.takenHour,
                                style: TextStyle(
                                  color: (isTime || posology.taken)
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
