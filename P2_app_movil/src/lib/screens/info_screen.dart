import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/provider.dart';
import '../models/medication.dart';

class InfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(    
      body: Consumer<MedicationProvider>(
        builder: (context, medicationProvider, child) {
          if (medicationProvider.isLoading) { // Cargando
            return Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ));
          }
          if (medicationProvider.errorMessage.isNotEmpty) { // Mensaje de error
            return Center(child: Text(medicationProvider.errorMessage));
          }
          if (medicationProvider.medications.isEmpty) { // No hay medicamentos
            return Center(child: Text('No hay medicamentos disponibles'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lista de Medicamentos
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: medicationProvider.medications.length,
                  itemBuilder: (context, index) {
                    final medication = medicationProvider.medications[index];
                    return MedicationTile(medication: medication);  // Widget para cada medicamento
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

class MedicationTile extends StatefulWidget {
  final Medication medication;
  MedicationTile({required this.medication});

  @override
  _MedicationTileState createState() => _MedicationTileState();
}

class _MedicationTileState extends State<MedicationTile> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16), // Bordes redondeados para la tarjeta
      ),
      elevation: 4, // Sombra para dar un efecto de profundidad
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Eliminar líneas negras
          child: ExpansionTile(
          title: Text(widget.medication.name),
          iconColor: Colors.green,          // Expandido
          collapsedIconColor: Colors.green, // Contraido
          children: [
              Container(
              margin: const EdgeInsets.only(top: 0, bottom: 8, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Dosis: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${widget.medication.dosage}mg'),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Fecha de inicio: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${widget.medication.startDate}'),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Duración del tratamiento: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${widget.medication.treatmentDuration} días'),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Posologías: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(widget.medication.posologies.map((posology) => '${posology.hour}:${posology.minute.toString().padLeft(2, '0')}').join(', ')),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Object? {
  get formattedTime => null;
}
