# Diseño del Software

Este documento describe el diseño del software para la aplicación basada en el patrón arquitectónico seleccionado.

## Casos de Uso

Aquí se describen los principales casos de uso de la aplicación:

- **Añadir Paciente**: El usuario puede añadir un nuevo paciente ingresando su nombre, apellido, DNI y fecha de nacimiento.
- **Añadir Medicamento**: El usuario puede añadir un medicamento a un paciente existente.

## Patrón Arquitectónico

Se ha seleccionado el patrón **Model-View-Presenter (MVP)** para gestionar el estado de la aplicación. Este patrón separa la lógica de negocio (modelo), la vista (interfaz de usuario) y el presentador (comunicación entre vista y modelo).

## Diseño Estático

A continuación, el diagrama de clases que representa la estructura estática de la aplicación, basada en el patrón MVP, integrando la lógica de pacientes y medicamentos según la interfaz proporcionada.

```mermaid
classDiagram
    class Patient {
        +int id
        +str code
        +str name
        +str surname
    }
    
    class Medication {
        +int id
        +str name
        +float dosage
        +str start_date
        +int treatment_duration
        +int patient_id
    }

    class Posology {
        +int id
        +int hour
        +int minute
        +int medication_id
    }

    class GPatient {
        +int id
        +str code
        +str name
        +str surname
        +bool starred
    }

    class GMedication {
        +int id
        +str name
        +int dosage
        +str start_date
        +int treatment_duration
        +int patient_id
    }

    class GPosology {
        +int id
        +int hour
        +int minute
        +int medication_id
    }

    class PatientModel {
        -_make_request(method: str, url: str, data: dict)
        +get_patients(offset: int, limit: int) list
        +add_patient(data: dict) Patient
        +get_patient_by_code(code: str) Patient
        +get_patient(id: int) Patient
        +update_patient(id: int, data: dict) Patient
        +delete_patient(id: int)
        +add_medication(patient_id: int, data: dict) Medication
        +get_all_medications(patient_id: int) list
        +get_medication(patient_id: int, medication_id: int) Medication
        +update_medication(patient_id: int, medication_id: int, data: dict) Medication
        +delete_medication(patient_id: int, medication_id: int)
        +add_posology(patient_id: int, medication_id: int, data: dict) Posology
        +get_posologies(patient_id: int, medication_id: int) list
        +update_posology(patient_id: int, medication_id: int, posology_id: int, data: dict) Posology
        +delete_posology(patient_id: int, medication_id: int, posology_id: int)
    }

    class View {
        +handler PatientViewHandler
        +data Gio.ListStore
        +medication_data Gio.ListStore
        +on_activate(app: Gtk.Application)
        +set_handler(handler: PatientViewHandler)
        -_build_ui(app: Gtk.Application)
        +show_message(msg: str)
        +set_patients(patients: list)
        +set_patient(code: str, name: str, surname: str)
        -_filter_func(patient: GPatient, _)
        -_on_search_entry_changed(search_entry)
        +on_patient_selected(patient_id: int)
        +update_patients(patients: list[GPatient])
        +add_patient_button_clicked(button: Gtk.Button)
        -_on_add_patient_dialog_response(dialog, code_entry, name_entry, surname_entry)
        +set_medications(medications: list)
        +show_patient_details(patient, medications)
        -_on_add_medication_button_clicked(button: Gtk.Button, patient_id: int)
        -_on_add_medication_dialog_response(dialog, response_id, patient_id, name_entry, dosage_entry, start_date_entry, duration_entry, posology_entry)
        -_on_delete_patient_button_clicked(button, patient_id)
        -_on_delete_patient_dialog_response(dialog, response, patient_id)
        -_on_medication_clicked(medication)
        +show_medication_details(patient_id, medication)
        -_on_edit_medication_button_clicked(button, medication, posologies)
        -_on_edit_medication_dialog(patient_id: int, medication, posologies)
        -_on_edit_medication_dialog_response(dialog, response_id, patient_id, name_entry, dosage_entry, start_date_entry, duration_entry, posology_entry, existing_medication)
        +show_success_message(message)
        +show_error_message(message)
        -_on_delete_medication_button_clicked(button, patient_id, medication_id, edit_dialog)
        -_on_delete_medication_dialog_response(dialog, response, patient_id, medication_id, edit_dialog)
    }

    class PatientPresenter {
        -model PatientModel
        -view View
        +run(application_id: str)
        +init_list()
        -fetch_patients()
        +on_patient_selected(id: int)
        -select_patient(id: int)
        +on_add_patient(patient_data: dict)
        -add_patient(patient_data: dict)
        +on_update_patient(id: int, updated_data: dict)
        -update_patient(id: int, updated_data: dict)
        +on_delete_patient(id: int)
        -delete_patient(id: int)
        +on_search_patients(query: str)
        -search_patients(query: str)
        +on_load_medications(patient_id: int)
        -load_medications(patient_id: int) list
        +on_add_medication(patient_id: int, medication_data: dict) int
        -_add_medication(patient_id: int, medication_data: dict) int
        +on_update_medication(patient_id: int, medication_id: int, updated_data: dict)
        -_update_medication(patient_id: int, medication_id: int, updated_data: dict)
        +on_delete_medication(patient_id: int, medication_id: int)
        -_delete_medication(patient_id: int, medication_id: int)
        +on_load_posologies(patient_id: int, medication_id: int)
        -_load_posologies(patient_id: int, medication_id: int)
        +on_add_posology(patient_id: int, medication_id: int, posology_data: dict)
        -_add_posology(patient_id: int, medication_id: int, posology_data: dict, show_message_once: bool)
        +on_update_posology(patient_id: int, medication_id: int, posology_id: int, updated_data: dict)
        -_update_posology(patient_id: int, medication_id: int, posology_id: int, updated_data: dict)
        +on_delete_posology(patient_id: int, medication_id: int, posology_id: int)
        -_delete_posology(patient_id: int, medication_id: int, posology_id: int)
        +list_posologies(patient_id: int, medication_id: int) list
    }

    PatientModel --> Patient
    PatientModel --> Medication
    PatientModel --> Posology
    PatientPresenter --> PatientModel
    PatientPresenter --> View
    View --> GPatient
    View --> GMedication
    View --> GPosology
