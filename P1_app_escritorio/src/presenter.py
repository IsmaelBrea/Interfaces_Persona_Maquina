from typing import Any  # Importa el tipo Any para usar en anotaciones
from view import View, run  # Importa las clases para la vista y para ejecutar la aplicación
from model import PatientModel, ModelException  # Importa el modelo de paciente y la excepción personalizada

import threading
import time
import gettext

from threading import Thread
from gi.repository import GLib

run_on_main_thread = GLib.idle_add    # Permite ejecutar una función en el hilo principal de la aplicación

COUNT = 10  # Establece el número máximo de pacientes que se mostrarán por página

_ = gettext.gettext  # Añadimos esta línea para facilitar la traducción

class PatientPresenter:
    def __init__(self, model: PatientModel, view: View):
        """
        Inicializa el presentador de pacientes.
        
        :param model: Objeto que maneja la lógica de negocio de pacientes.
        :param view: Objeto que maneja la interfaz de usuario para pacientes.
        """
        self.model = model  # Guarda la referencia al modelo de pacientes
        self.view = view  # Guarda la referencia a la vista de pacientes
        self.view.presenter=self  # Asocia el presentador a la vista

    def run(self, application_id: str):
        """
        Configura y ejecuta la vista de la aplicación.

        :param application_id: Identificador único de la aplicación.
        """
        self.view.set_handler(self)  # Asocia el presentador a la vista
        run(application_id, on_activate=self.view.on_activate)  # Inicia la vista


    # MÉTODOS PARA LOS PACIENTES
    def init_list(self) -> None:
        """
        Inicializa la lista de pacientes
        """
        t = Thread(target=self.fetch_patients)
        t.start()

    def fetch_patients(self) -> None:
        """
        Obtiene los pacientes del modelo y los muestra en la vista
        """
        try:
            patients = self.model.get_patients(0, COUNT)
            if len(patients) > 0:
                run_on_main_thread(self.view.set_patients, patients)
            else:
                run_on_main_thread(self.view.set_sensitive_next, False)
                run_on_main_thread(self.view.show_message, _("No more patients"))
        except Exception as e:
            run_on_main_thread(self.view.show_message, str(e))


    def on_patient_selected(self, id: int) -> None:
        """
        Maneja cuando se selecciona un paciente.
        """
        # Crea un nuevo hilo para ejecutar la selección del paciente
        t = Thread(target=self.select_patient, args=(id,))
        # Inicia el hilo
        t.start()

    # Lógica cuando se selecciona un paciente
    def select_patient(self, id: int) -> None:
        try:
            patient = self.model.get_patient(id)
            medications = self.model.get_all_medications(id)
            run_on_main_thread(self.view.show_patient_details, patient, medications)
        except Exception as e:
            run_on_main_thread(self.view.show_message, str(e))

            
    def on_load_page(self, idx: int) -> None:
        """
        Carga una página específica de pacientes.

        :param idx: Índice de la página a cargar.
        """
        if idx >= 0:  # Verifica si el índice es válido
            try:
                patients = self.model.get_patients(COUNT * idx, COUNT)  # Obtiene pacientes de la página solicitada
                if len(patients) > 0:  # Si hay pacientes en la página
                    self.view.set_patients(patients)  # Muestra los pacientes en la vista
                    self.view.set_sensitive_previous(True)  # Habilita el botón 'Anterior'
                    self.view.set_sensitive_next(True)  # Habilita el botón 'Siguiente'
                else:
                    self.view.set_sensitive_next(False)  # Desactiva el botón 'Siguiente' si no hay más pacientes
                    self.view.show_message(_("No more patients"))  # Muestra un mensaje indicando que no hay más pacientes
            except Exception as e:
                self.view.show_message(str(e))  # Muestra un mensaje de error si ocurre una excepción
        else:
            self.view.set_sensitive_previous(False)  # Desactiva el botón 'Anterior' si el índice es negativo


    def on_add_patient(self, patient_data: dict) -> None:
        """
        Maneja la adición de un nuevo paciente
        """
        t = Thread(target=self.add_patient, args=(patient_data,))
        t.start()

    # Lógica para agregar un paciente
    def add_patient(self, patient_data: dict) -> None:
        try:
            new_patient = self.model.add_patient(patient_data)
            run_on_main_thread(self.view.show_message, _("Paciente {} agregado con éxito.").format(new_patient.name))
            run_on_main_thread(self.init_list)
        except ValueError as ve:
            run_on_main_thread(self.view.show_message, _("Error al agregar paciente: {}").format(str(ve)))
        except Exception as e:
            run_on_main_thread(self.view.show_message, str(e))

    
    def on_update_patient(self, id: int, updated_data: dict) -> None:
        """
        Maneja la actualización de un paciente
        """
        t = Thread(target=self.update_patient, args=(id, updated_data))
        t.start()

    # Lógica para actualizar un paciente   
    def update_patient(self, id: int, updated_data: dict) -> None:
        try:
            updated_patient = self.model.update_patient(id, updated_data)  # Actualiza el paciente en el modelo
            run_on_main_thread(self.view.show_message(_("Paciente {} actualizado con éxito.").format(updated_patient.name)))  # Muestra un mensaje de éxito
            run_on_main_thread(self.init_list())  # Recarga la lista de pacientes
        except Exception as e:
            run_on_main_thread(self.view.show_message(str(e)))  # Muestra un mensaje de error si ocurre una excepción

    def on_delete_patient(self, id: int) -> None:
        """
        Maneja la eliminación de un paciente
        """
        t = Thread(target=self.delete_patient, args=(id,))
        t.start()

    def delete_patient(self, id: int) -> None:
        try:
            # Eliminar el paciente en un hilo separado
            self.model.delete_patient(id)
            # Actualizar la interfaz de usuario en el hilo principal
            run_on_main_thread(self.view.show_message, _("Paciente eliminado con éxito."))
            run_on_main_thread(self.init_list)  # Recargar la lista de pacientes
        except Exception as e:
            run_on_main_thread(self.view.show_message, str(e))
            
    
    def on_search_patients(self, query: str) -> None:
        """
        Maneja la búsqueda de pacientes
        """
        t = Thread(target=self.search_patients, args=(query,))
        t.start()

    # Lógica para buscar pacientes
    def search_patients(self, query: str) -> None:
    
        try:
            results = self.model.search_patients(query)
            self.view.set_patients(results)
        except Exception as e:
            self.view.show_message(str(e))

    
    # MÉTODOS PARA LOS MEDICAMENTOS
    def on_load_medications(self, patient_id: int) -> None:
        """
        Carga y muestra todos los medicamentos de un paciente
        """
        # Crea un nuevo hilo para cargar los medicamentos
        t = Thread(target=self.load_medications, args=(patient_id,))
        t.start()

    # Lógica para cargar los medicamentos de un paciente
    def load_medications(self, patient_id: int) -> list:
        try:
            # Obtiene medicamentos del modelo
            medications = self.model.get_all_medications(patient_id)
            # Actualiza la vista con los medicamentos (debe ser llamado en el hilo principal)
            run_on_main_thread(self.view.set_medications, medications)
            return medications
        except Exception as e:
            # Muestra un mensaje de error si ocurre una excepción
            run_on_main_thread(self.view.show_message, str(e))
            return []  # Retorna una lista vacía en caso de error


    def on_add_medication(self, patient_id: int, medication_data: dict) -> None:
        """
        Maneja la adición de un nuevo medicamento a un paciente
        """
        # Crea un nuevo hilo para ejecutar la adición de medicamento
        t = Thread(target=self._add_medication, args=(patient_id, medication_data))
        t.start()
        

    def _add_medication(self, patient_id: int, medication_data: dict) -> None:
        try:
            # Verificar que todos los campos requeridos estén presentes
            required_fields = ['name', 'dosage', 'start_date', 'treatment_duration']
            for field in required_fields:
                if field not in medication_data or not medication_data[field]:
                    raise ValueError(_("El campo '{}' es requerido y no puede estar vacío").format(field))

            # Convertir los tipos de datos
            medication_data['dosage'] = float(medication_data['dosage'])
            medication_data['treatment_duration'] = int(medication_data['treatment_duration'])
            
            # Validar la fecha de inicio
            from datetime import datetime
            try:
                datetime.strptime(medication_data['start_date'], '%Y-%m-%d')
            except ValueError:
                raise ValueError(_("La fecha de inicio debe estar en formato YYYY-MM-DD"))

            new_medication = self.model.add_medication(patient_id, medication_data)
            run_on_main_thread(self.view.show_message, _("Medicamento {} agregado con éxito.").format(new_medication.name))
            self.on_load_medications(patient_id)  # Cargar medicamentos después de agregar
        except ValueError as ve:
            run_on_main_thread(self.view.show_message, _("Error en los datos del medicamento: {}").format(str(ve)))
        except ModelException as me:
            run_on_main_thread(self.view.show_message, _("Error del modelo: {}").format(str(me)))
        except Exception as e:
            run_on_main_thread(self.view.show_message, _("Error inesperado: {}").format(str(e)))
            
    def on_update_medication(self, patient_id: int, medication_id: int, updated_data: dict) -> None:
        """
        Maneja la actualización de un medicamento de un paciente
        """
        # Crea un nuevo hilo para actualizar el medicamento
        t = Thread(target=self._update_medication, args=(patient_id, medication_id, updated_data))
        t.start()

    # Lógica para actualizar un medicamento
    def _update_medication(self, patient_id: int, medication_id: int, updated_data: dict) -> None:
        try:
            # Actualiza el medicamento
            updated_medication = self.model.update_medication(patient_id, medication_id, updated_data)
            # Muestra un mensaje de éxito
            #run_on_main_thread(self.view.show_message, _("Medicamento {} actualizado con éxito.").format(updated_medication.name))
            # Recarga la lista de medicamentos
            self.on_load_medications(patient_id)
        except Exception as e:
            # Muestra un mensaje de error si ocurre una excepción
            run_on_main_thread(self.view.show_message, str(e))

    def on_delete_medication(self, patient_id: int, medication_id: int) -> None:
        # Crea un nuevo hilo para eliminar el medicamento
        t = Thread(target=self._delete_medication, args=(patient_id, medication_id))
        t.start()

    def _delete_medication(self, patient_id: int, medication_id: int) -> None:
        try:
            # Elimina el medicamento
            self.model.delete_medication(patient_id, medication_id)
            # Muestra un mensaje de éxito
            run_on_main_thread(self.view.show_message, _("Medicamento eliminado con éxito."))
            # Recarga la lista de medicamentos
            self.on_load_medications(patient_id)
        except Exception as e:
            # Muestra un mensaje de error si ocurre una excepción
            run_on_main_thread(self.view.show_message, str(e))


        # MÉTODOS PARA LAS POSOLOGÍAS
    def on_load_posologies(self, patient_id: int, medication_id: int) -> None:
        """
        Carga y muestra todas las posologías de un medicamento de un paciente.
        Ejecuta la carga en un hilo separado.

        :param patient_id: ID del paciente para el cual cargar las posologías.
        :param medication_id: ID del medicamento para el cual cargar las posologías.
        """
        t = Thread(target=self._load_posologies, args=(patient_id, medication_id))
        t.start()

    def _load_posologies(self, patient_id: int, medication_id: int) -> None:
        """
        Lógica para cargar las posologías en un hilo separado.
        """
        try:
            posologies = self.model.get_posologies(patient_id, medication_id)
        except Exception as e:
            run_on_main_thread(self.view.show_message, str(e))

    def on_add_posology(self, patient_id: int, medication_id: int, posology_data: dict) -> None:
        """
        Maneja la adición de una nueva posología en un hilo separado.

        :param patient_id: ID del paciente al que se le agregará la posología.
        :param medication_id: ID del medicamento al que se le agregará la posología.
        :param posology_data: Diccionario con los datos de la nueva posología.
        """
        t = Thread(target=self._add_posology, args=(patient_id, medication_id, posology_data))
        t.start()

    def _add_posology(self, patient_id: int, medication_id: int, posology_data: dict, show_message_once: bool = True) -> None:
        """
        Lógica para agregar una posología en un hilo separado.
        """
        try:
            # Verificar campos requeridos
            required_fields = ['time', 'quantity']
            for field in required_fields:
                if field not in posology_data or not posology_data[field]:
                    raise ValueError(_("El campo '{}' es requerido y no puede estar vacío").format(field))

            # Convertir tipos de datos si es necesario
            posology_data['quantity'] = float(posology_data['quantity'])
            
            # Agregar la posología
            new_posology = self.model.add_posology(patient_id, medication_id, posology_data)
            
            # Solo mostrar el mensaje al final si se especifica
            #if show_message_once:
                #run_on_main_thread(self.view.show_message, _("Posologías agregadas con éxito."))
            
            # Refrescar la lista de posologías
            run_on_main_thread(self._load_posologies, patient_id, medication_id)
            
        except ValueError as ve:
            run_on_main_thread(self.view.show_message, _("Error en los datos de la posología: {}").format(str(ve)))
        except Exception as e:
            run_on_main_thread(self.view.show_message, str(e))

    def on_update_posology(self, patient_id: int, medication_id: int, posology_id: int, updated_data: dict) -> None:
        """
        Maneja la actualización de una posología en un hilo separado.

        :param patient_id: ID del paciente que tiene la posología.
        :param medication_id: ID del medicamento al que pertenece la posología.
        :param posology_id: ID de la posología a actualizar.
        :param updated_data: Diccionario con los nuevos datos de la posología.
        """
        t = Thread(target=self._update_posology, args=(patient_id, medication_id, posology_id, updated_data))
        t.start()

    def _update_posology(self, patient_id: int, medication_id: int, posology_id: int, updated_data: dict) -> None:
        """
        Lógica para actualizar una posología en un hilo separado.
        """
        try:
            # Verificar y convertir datos si es necesario
            if 'quantity' in updated_data:
                updated_data['quantity'] = float(updated_data['quantity'])

            updated_posology = self.model.update_posology(patient_id, medication_id, posology_id, updated_data)
            #run_on_main_thread(self.view.show_message, _("Posología actualizada con éxito."))
            run_on_main_thread(self._load_posologies, patient_id, medication_id)
        except ValueError as ve:
            run_on_main_thread(self.view.show_message, _("Error en los datos de la posología: {}").format(str(ve)))
        except Exception as e:
            run_on_main_thread(self.view.show_message, str(e))

    def on_delete_posology(self, patient_id: int, medication_id: int, posology_id: int) -> None:
        """
        Maneja la eliminación de una posología en un hilo separado.

        :param patient_id: ID del paciente que tiene la posología.
        :param medication_id: ID del medicamento que tiene la posología.
        :param posology_id: ID de la posología a eliminar.
        """
        t = Thread(target=self._delete_posology, args=(patient_id, medication_id, posology_id))
        t.start()

    def _delete_posology(self, patient_id: int, medication_id: int, posology_id: int) -> None:
        """
        Lógica para eliminar una posología en un hilo separado.
        """
        try:
            self.model.delete_posology(patient_id, medication_id, posology_id)
            run_on_main_thread(self._load_posologies, patient_id, medication_id)
        except Exception as e:
            run_on_main_thread(self.view.show_message, str(e))
            
    def list_posologies(self, patient_id: int, medication_id: int) -> list:
        """
        Devuelve una lista con las posologías de un medicamento de un paciente.

        :param patient_id: ID del paciente.
        :param medication_id: ID del medicamento.
        :return: Lista de posologías.
        """
        try:
            posologies = self.model.get_posologies(patient_id, medication_id)  # Obtiene posologías del modelo
            posologies.sort(key=lambda posology: posology.hour) #ordenar por hora
            return posologies
        except Exception as e:
            self.view.show_message(str(e))  # Muestra un mensaje de error si ocurre una excepción
            return []  # Retorna una lista vacía en caso de error