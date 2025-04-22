## Diseño Dinámico

```mermaid
sequenceDiagram
    View->>PatientPresenter: on_add_medication(patient_id, medication_data)
    PatientPresenter->>PatientModel: add_medication(patient_id, medication_data)
    PatientModel->>Server: POST /patients/{id}/medications
    Server-->>PatientModel: Nuevo medicamento
    PatientModel-->>PatientPresenter: Objeto Medication
    PatientPresenter->>View: show_message("Medicamento añadido")
    PatientPresenter->>PatientPresenter: on_load_medications(patient_id)

    User->>View: Edita un medicamento
    View->>View: _on_edit_medication_button_clicked()
    View->>View: Muestra diálogo de editar medicamento
    User->>View: Modifica datos del medicamento
    View->>PatientPresenter: on_update_medication(patient_id, medication_id, updated_data)
    PatientPresenter->>PatientModel: update_medication(patient_id, medication_id, updated_data)
    PatientModel->>Server: PATCH /patients/{id}/medications/{med_id}
    Server-->>PatientModel: Medicamento actualizado
    PatientModel-->>PatientPresenter: Objeto Medication actualizado
    PatientPresenter->>View: show_success_message("Cambios guardados")

    User->>View: Ver posologías de un medicamento
    View->>PatientPresenter: on_load_posologies(patient_id, medication_id)
    PatientPresenter->>PatientModel: get_posologies(patient_id, medication_id)
    PatientModel->>Server: GET /patients/{id}/medications/{med_id}/posologies
    Server-->>PatientModel: Lista de posologías
    PatientModel-->>PatientPresenter: Lista de posologías
    PatientPresenter->>View: Actualiza vista con posologías

    User->>View: Añade una posología
    View->>PatientPresenter: on_add_posology(patient_id, medication_id, posology_data)
    PatientPresenter->>PatientModel: add_posology(patient_id, medication_id, posology_data)
    PatientModel->>Server: POST /patients/{id}/medications/{med_id}/posologies
    Server-->>PatientModel: Nueva posología
    PatientModel-->>PatientPresenter: Objeto Posology
    PatientPresenter->>View: show_message("Posología añadida")

    User->>View: Elimina un paciente
    View->>View: _on_delete_patient_button_clicked()
    View->>View: Muestra diálogo de confirmación
    User->>View: Confirma eliminación
    View->>PatientPresenter: on_delete_patient(id)
    PatientPresenter->>PatientModel: delete_patient(id)
    PatientModel->>Server: DELETE /patients/{id}
    Server-->>PatientModel: Confirmación
    PatientModel-->>PatientPresenter: Confirmación
    PatientPresenter->>View: show_message("Paciente eliminado")
    PatientPresenter->>PatientPresenter: init_list()

    User->>View: Elimina un medicamento
    View->>View: _on_delete_medication_button_clicked()
    View->>View: Muestra diálogo de confirmación
    User->>View: Confirma eliminación
    View->>PatientPresenter: on_delete_medication(patient_id, medication_id)
    PatientPresenter->>PatientModel: delete_medication(patient_id, medication_id)
    PatientModel->>Server: DELETE /patients/{id}/medications/{med_id}
    Server-->>PatientModel: Confirmación
    PatientModel-->>PatientPresenter: Confirmación
    PatientPresenter->>View: show_message("Medicamento eliminado")
    PatientPresenter->>PatientPresenter: on_load_medications(patient_id)


