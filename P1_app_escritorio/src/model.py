import requests

SERVER_URL = "http://localhost:8000"  # URL base del servidor donde están los recursos

# Excepción personalizada para manejar errores del modelo
class ModelException(Exception):
    def __init__(self, msg: str):
        super().__init__(msg)

# Clase que representa un paciente. Usa los datos proporcionados para inicializar atributos.
class Patient:
    def __init__(self, data=None):
        if data is not None:
            for key, value in data.items():
                setattr(self, key, value)

# Clase que representa un medicamento
class Medication:
    def __init__(self, data=None):
        if data is not None:
            for key, value in data.items():
                setattr(self, key, value)

# Clase que representa una posología
class Posology:
    def __init__(self, data=None):
        if data is not None:
            for key, value in data.items():
                setattr(self, key, value)


# Clase que contiene todas las operaciones para manejar pacientes, medicamentos, posologías e intakes
class PatientModel:

    def __init__(self):
        pass

    # Se encarga de realizar la solicitud HTTP usando el método especificado (GET, POST, PATCH, DELETE)
    def _make_request(self, method: str, url: str, data: dict = None):
        methods = {
            "GET": requests.get,
            "POST": requests.post,
            "PATCH": requests.patch,
            "DELETE": requests.delete
        }

        # Realizamos la petición con el método correspondiente, incluyendo datos si es necesario
        response = methods[method](url, json=data) if data else methods[method](url)
        
        try:
            # Intentamos convertir la respuesta en JSON, si es posible
            response_data = response.json() if response.content else {}
        except ValueError:
            response_data = {}  # Si no se puede parsear el contenido como JSON, lo dejamos vacío

        # Si la respuesta es correcta (200-299), devolvemos los datos
        if response.ok:
            return response_data
        else:
            # Si la respuesta tiene un error, lanzamos una excepción con el detalle del error
            raise ModelException(response_data.get("detail", f"Error {response.status_code}: {response.text}"))
        


    """ CRUD DE PACIENTES """
    # Obtener todos los pacientes con paginación
    def get_patients(self, offset: int, limit: int) -> list:
        url = f"{SERVER_URL}/patients?offset={offset}&limit={limit}"
        response_data = self._make_request("GET", url)
        # Convertimos cada paciente en un objeto Patient
        return [Patient(item) for item in response_data]

    # Crear un nuevo paciente con los datos proporcionados
    def add_patient(self, data: dict) -> Patient:
        url = f"{SERVER_URL}/patients"
        response = requests.post(url, json=data)  # Enviar los datos al servidor con POST
        data = response.json()
        if response.ok:  # Si la respuesta es exitosa, devuelve un objeto Patient
            return Patient(data)
        else:
            raise ModelException(data["detail"])  # Si hay un error, lanza una excepción

    # Obtener un paciente usando un código específico
    def get_patient_by_code(self, code: str) -> Patient:
        url = f"{SERVER_URL}/patients?code={code}"
        response = requests.get(url)
        data = response.json()
        if response.ok:
            return Patient(data)
        else:
            raise ModelException(data["detail"])

    # Obtener un paciente por su ID
    def get_patient(self, id: int) -> Patient:
        url = f"{SERVER_URL}/patients/{id}"
        response = requests.get(url)
        data = response.json()
        if response.ok:
            return Patient(data)
        else:
            raise ModelException(data["detail"])

    # Actualizar la información de un paciente por su ID
    def update_patient(self, id: int, data: dict) -> Patient:
        url = f"{SERVER_URL}/patients/{id}"
        response = requests.patch(url, json=data)  # Usar PATCH para modificar parcialmente
        data = response.json()
        if response.ok:
            return Patient(data)
        else:
            raise ModelException(data["detail"])

    # Eliminar un paciente por su ID
    def delete_patient(self, id: int):
        url = f"{SERVER_URL}/patients/{id}"
        response = requests.delete(url)
        if not response.ok:
            data = response.json()
            raise ModelException(data["detail"])



    """ CRUD DE MEDICAMENTOS """
    # Agregar un medicamento a un paciente específico
    def add_medication(self, patient_id: int, data: dict) -> Medication:
        url = f"{SERVER_URL}/patients/{patient_id}/medications"
        response = requests.post(url, json=data)
        data = response.json()
        if response.ok:
            return Medication(data)
        else:
            raise ModelException(data["detail"])

    # Obtener todos los medicamentos de un paciente
    def get_all_medications(self, patient_id: int) -> list:
        url = f"{SERVER_URL}/patients/{patient_id}/medications"
        response = requests.get(url)
        if response.status_code == 200:
            medications_data = response.json()
            return [Medication(item) for item in medications_data]
        else:
            raise ModelException(response.json()["detail"])

    # Obtener un medicamento específico de un paciente
    def get_medication(self, patient_id: int, medication_id: int) -> Medication:
        url = f"{SERVER_URL}/patients/{patient_id}/medications/{medication_id}"
        response = requests.get(url)
        data = response.json()
        if response.ok:
            return Medication(data)
        else:
            raise ModelException(data["detail"])

    # Actualizar un medicamento específico de un paciente
    def update_medication(self, patient_id: int, medication_id: int, data: dict) -> Medication:
        url = f"{SERVER_URL}/patients/{patient_id}/medications/{medication_id}"
        response = requests.patch(url, json=data)
        data = response.json()
        if response.ok:
            return Medication(data)
        else:
            raise ModelException(data["detail"])

    # Eliminar un medicamento de un paciente
    def delete_medication(self, patient_id: int, medication_id: int):
        url = f"{SERVER_URL}/patients/{patient_id}/medications/{medication_id}"
        response = requests.delete(url)
        if not response.ok:
            data = response.json()
            raise ModelException(data["detail"])



    """ CRUD DE POSOLOGÍAS """
    # Agregar una posología a un medicamento de un paciente
    def add_posology(self, patient_id: int, medication_id: int, data: dict) -> Posology:
        url = f"{SERVER_URL}/patients/{patient_id}/medications/{medication_id}/posologies"
        response = requests.post(url, json=data)
        data = response.json()
        if response.ok:
            return Posology(data)
        else:
            raise ModelException(data["detail"])

    # Obtener todas las posologías de un medicamento de un paciente
    def get_posologies(self, patient_id: int, medication_id: int) -> list:
        url = f"{SERVER_URL}/patients/{patient_id}/medications/{medication_id}/posologies"
        response = requests.get(url)
        data = response.json()
        if response.ok:
            return [Posology(item) for item in data]  # Convertir cada item en un objeto Posology
        else:
            raise ModelException(data["detail"])

    # Eliminar una posología de un medicamento
    def delete_posology(self, patient_id: int, medication_id: int, posology_id: int):
        url = f"{SERVER_URL}/patients/{patient_id}/medications/{medication_id}/posologies/{posology_id}"
        response = requests.delete(url)
        if not response.ok:
            data = response.json()
            raise ModelException(data["detail"])
        
    def update_posology(self, patient_id: int, medication_id: int, posology_id: int, data: dict) -> Posology:
        url = f"{SERVER_URL}/patients/{patient_id}/medications/{medication_id}/posologies/{posology_id}"
        response = requests.patch(url, json=data)
        data = response.json()
        if response.ok:
            return Posology(data)
        else:
            raise ModelException(data["detail"])
