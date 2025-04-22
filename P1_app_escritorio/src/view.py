# Importar las bibliotecas necesarias
from typing import Callable, Protocol, Any
import gi
import gettext

# Requerir la versión de GTK 4.0
gi.require_version('Gtk', '4.0')
from gi.repository import Gtk, Gio, GObject, GLib

_ = gettext.gettext  # Añadimos esta línea para facilitar la traducción

# Función para ejecutar la aplicación GTK
def run(application_id: str, on_activate: Callable) -> None:
    # Crear una nueva instancia de la aplicación
    app = Gtk.Application(application_id=application_id)
    # Conectar la señal de activación a la función proporcionada
    app.connect('activate', on_activate)
    # Ejecutar la aplicación
    app.run()


# Clase que representa un paciente
class GPatient(GObject.GObject):
    def __init__(self, id: int, code: str, name: str, surname: str, starred: bool = False):
        # Inicializar la clase base GObject
        super().__init__()
        # Asignar los atributos del paciente
        self.id = id
        self.code = code
        self.name = name
        self.surname = surname


# Clase que representa un medicamento
class GMedication(GObject.GObject):
    def __init__(self, id: int, name: str, dosage: int, start_date: str, treatment_duration: int, patient_id: int):
        super().__init__()
        self.id = id
        self.name = name
        self.dosage = dosage
        self.start_date = start_date
        self.treatment_duration = treatment_duration
        self.patient_id = patient_id
        

# Clase que representa la posología de un medicamento
class GPosology(GObject.GObject):
    def __init__(self, id: int, hour: int, minute: int, medication_id: int):
        super().__init__()
        self.id = id  # Identificador único de la posología
        self.hour = hour  # Hora de la toma
        self.minute = minute  # Minuto de la toma
        self.medication_id = medication_id  # Identificador de la medicación asociada


# Protocolo que define las interacciones de la vista con el controlador
class PatientViewHandler(Protocol):
    def init_list(self) -> None: pass
    def fetch_patients(self) -> list: pass
    def on_patient_selected(self, id: int) -> None: pass
    def select_patient(self, id: int) -> None: pass
    def on_load_page(self, idx: int) -> None: pass
    def on_add_patient(self, patient_data: dict) -> None: pass
    def add_patient(self, patient_data: dict) -> None: pass
    def on_update_patient(self, id: int, updated_data: dict) -> None: pass
    def update_patient(self, id: int, updated_data: dict) -> None: pass
    def on_delete_patient(self, id: int) -> None: pass
    def on_search_patients(self, query: str) -> None: pass
    def search_patients(self, query: str) -> None: pass
    def on_load_medications(self, patient_id: int) -> None: pass
    def load_medications(self, patient_id: int) -> None: pass
    def on_add_medication(self, patient_id: int, medication_data: dict) -> int: pass
    def add_medication(self, patient_id: int, medication_data: dict) -> int: pass
    def on_update_medication(self, patient_id: int, medication_id: int, updated_data: dict) -> None: pass
    def update_medication(self, patient_id: int, medication_id: int, updated_data: dict) -> None: pass
    def on_delete_medication(self, patient_id: int, medication_id: int) -> None: pass
    def delete_medication(self, patient_id: int, medication_id: int) -> None : pass
    def on_load_posologies(self, patient_id: int, medication_id: int) -> None: pass
    def load_posologies(self, patient_id: int, medication_id: int) -> None: pass
    def load_posologies(self, patient_id: int, medication_id: int) -> None: pass
    def on_add_posology(self, patient_id: int, medication_id: int, posology_data: dict) -> None: pass
    def add_posology(self, patient_id: int, medication_id: int, posology_data: dict) -> None: pass
    def on_update_posology(self, patient_id: int, medication_id: int, posology_id: int, updated_data: dict) -> None: pass
    def update_posology(self, patient_id: int, medication_id: int, posology_id: int, updated_data: dict) -> None: pass
    def on_delete_posology(self, patient_id: int, medication_id: int, posology_id: int) -> None: pass
    def delete_posology(self, patient_id: int, medication_id: int, posology_id: int) -> None: pass
    def list_posologies(self, patient_id: int, medication_id: int) -> list: pass


# Clase que representa la vista de pacientes
class View:
    # Constructor de la clase
    def __init__(self):
        self.handler = None  # Manejar eventos
        self.data = Gio.ListStore(item_type=GPatient)  # Almacén de datos de pacientes
        self.medication_data = Gio.ListStore(item_type=GMedication)  # Almacén de medicamentos
    

    # Método llamado cuando la aplicación se activa
    def on_activate(self, app: Gtk.Application) -> None:
        self._build_ui(app)  # Construir la interfaz de usuario
        self.handler.init_list()  # Inicializar la lista de pacientes

    # Establecer el controlador de eventos
    def set_handler(self, handler: PatientViewHandler) -> None:
        self.handler = handler

   # Método privado para construir la interfaz de usuario
    def _build_ui(self, app: Gtk.Application) -> None:
        # Crear la ventana de la aplicación
        self.window = win = Gtk.ApplicationWindow(title=_("PACIENTES"), hexpand=True, vexpand=True)
        app.add_window(win)  # Añadir la ventana a la aplicación
        win.set_default_size(1500, 1000)  # Aumentar el tamaño de la ventana

        # Contenedor principal vertical
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        main_box.set_halign(Gtk.Align.CENTER)
        main_box.set_valign(Gtk.Align.CENTER)
        main_box.set_size_request(500, -1)  #anchura, altura

        # Título de la ventana
        title_label = Gtk.Label(label=_("PACIENTES"))
        title_label.set_markup("<span font='30'>PACIENTES</span>")  # Cambiar el tamaño del texto
        main_box.append(title_label)

        
        # Barra de búsqueda
        self.search_entry = Gtk.SearchEntry()
        self.search_entry.set_placeholder_text(_("Buscar paciente..."))
        self.search_entry.set_margin_top(32)
        self.search_entry.connect("search-changed", self._on_search_entry_changed)
        main_box.append(self.search_entry)


        # Encabezado de la lista de pacientes
        header_grid = Gtk.Grid(hexpand=True, halign=Gtk.Align.FILL, orientation=Gtk.Orientation.HORIZONTAL, margin_start=8, margin_end=8, margin_top=8)
        header_grid.set_column_homogeneous(True)

        header_surname = Gtk.Label(label=_("Apellido"), hexpand=True, halign=Gtk.Align.START)
        header_name = Gtk.Label(label=_("Nombre"), hexpand=True, halign=Gtk.Align.CENTER)
        header_code = Gtk.Label(label=_("Código"), hexpand=True, halign=Gtk.Align.END)

        header_grid.attach(header_surname, 0, 0, 1, 1)
        header_grid.attach(header_name, 1, 0, 1, 1)
        header_grid.attach(header_code, 2, 0, 1, 1)

        main_box.append(header_grid)
        main_box.append(header_grid)

        # Lista de pacientes
        self.listbox = Gtk.ListBox(hexpand=True, vexpand=True)
        self.listbox.set_selection_mode(Gtk.SelectionMode.SINGLE)

        # Función para crear cada fila a partir de un elemento de la lista
        def on_create_row(item: GPatient, user_data: Any) -> Gtk.Widget:
            grid = Gtk.Grid(hexpand=True, halign=Gtk.Align.FILL, orientation=Gtk.Orientation.HORIZONTAL, margin_start=8, margin_end=8, margin_top=4, margin_bottom=4)
            grid.set_column_homogeneous(True)

            label_surname = Gtk.Label(label=item.surname, hexpand=True, halign=Gtk.Align.START)
            label_name = Gtk.Label(label=item.name, hexpand=True, halign=Gtk.Align.CENTER)
            label_code = Gtk.Label(label=item.code, hexpand=True, halign=Gtk.Align.END)

            grid.attach(label_surname, 0, 0, 1, 1)
            grid.attach(label_name, 1, 0, 1, 1)
            grid.attach(label_code, 2, 0, 1, 1)

            return grid

        # Se une el modelo a la lista
        self.listbox.bind_model(self.data, on_create_row, None)
        self.listbox.connect("row-activated", lambda _, row: self.on_patient_selected(self.filtered_model[row.get_index()].id))

        # Crear filtro para la lista de pacientes
        self.filter = Gtk.CustomFilter.new(self._filter_func, self.data)
        self.filtered_model = Gtk.FilterListModel(model=self.data, filter=self.filter)

        # Vincular el modelo filtrado a la lista
        self.listbox.bind_model(self.filtered_model, on_create_row, None)


        # Habilitar el desplazamiento en el ListBox
        scrolledwindow = Gtk.ScrolledWindow()
        scrolledwindow.set_child(self.listbox)
        scrolledwindow.set_vexpand(True)
        scrolledwindow.set_max_content_height(500)
        scrolledwindow.set_min_content_height(500)
        scrolledwindow.set_propagate_natural_height(True)
        main_box.append(scrolledwindow)


        # Botón "Añadir paciente"
        add_button = Gtk.Button(label=_("Añadir paciente"))
        add_button.set_halign(Gtk.Align.CENTER)
        add_button.set_margin_top(30)
        add_button.connect("clicked", self.add_patient_button_clicked)
        main_box.append(add_button)

        # Añadir el contenedor principal a la ventana
        win.set_child(main_box)
        win.show()

     # Método para mostrar un mensaje en un cuadro de diálogo
    def show_message(self, msg: str) -> None:
        dialog = Gtk.Window(
            title="Warning", modal=True, resizable=False, transient_for=self.window)  # Crear ventana de mensaje
        if len(msg) > 200:
            dialog.set_default_size(120, 120)  # Ajustar tamaño si el mensaje es largo

        # Crear un contenedor para el mensaje
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16,
                      margin_top=24, margin_bottom=24, margin_start=48, margin_end=48)
        box.append(Gtk.Label(label=msg, wrap=True))  # Añadir mensaje al contenedor

        accept_button = Gtk.Button.new_with_label(_("Aceptar"))  # Botón de aceptación
        accept_button.connect("clicked", lambda _: dialog.close())  # Conectar el evento de clic

        box.append(accept_button)  # Añadir botón al contenedor
        dialog.set_child(box)  # Establecer contenedor como hijo del diálogo
        dialog.present()  # Presentar diálogo



    """ MÉTODOS PARA LA VISTA DE PACIENTES"""
     # Método para establecer los pacientes en el ListBox
    def set_patients(self, patients: list) -> None:
        self.data.remove_all()  # Limpiar la lista actual
        for patient in patients:
            # Añadir cada paciente a la lista
            self.data.append(GPatient(patient.id, patient.code,
                             patient.name, patient.surname))

    # Método para establecer los detalles del paciente seleccionado
    def set_patient(self, code: str, name: str, surname: str) -> None:
        # Establecer texto en los campos de entrada
        self.code_entry.get_buffer().set_text(code, -1)
        self.name_entry.get_buffer().set_text(name, -1)
        self.surname_entry.get_buffer().set_text(surname, -1)
    
    # Método de filtrado para pacientes
    def _filter_func(self, patient: GPatient, _):
        search_text = self.search_entry.get_text().lower()
        # Devuelve True si el paciente coincide con el texto de búsqueda
        return search_text in f"{patient.surname} {patient.name} {patient.code}".lower()

    # Método que se ejecuta cuando cambia el texto en la barra de búsqueda
    def _on_search_entry_changed(self, search_entry):
        self.filter.changed(Gtk.FilterChange.DIFFERENT)
    
    # Manejar el evento de selección de paciente
    def on_patient_selected(self, patient_id: int) -> None:
        if self.handler:
            self.handler.on_patient_selected(patient_id)
            self.window.hide()
    
    # Actualizar la lista de pacientes con los datos proporcionados
    def update_patients(self, patients: list[GPatient]) -> None:
        self.data.remove_all()
        for patient in patients:
            self.data.append(patient)


    # Maneja el evento de clic en el botón "Añadir paciente"
    def add_patient_button_clicked(self, button: Gtk.Button):
        dialog = Gtk.Dialog(title=_("Añadir Paciente"), transient_for=self.window, modal=True)
        dialog.set_default_size(800, 500)

        # Contenedor principal vertical
        form_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        form_box.set_halign(Gtk.Align.CENTER)
        form_box.set_valign(Gtk.Align.CENTER)
        form_box.set_size_request(700, -1)  # Anchura, altura
        dialog.set_child(form_box)

        # Código del paciente
        code_label = Gtk.Label(label=_("Código del paciente:"))
        code_label.set_halign(Gtk.Align.START)
        form_box.append(code_label)
        code_entry = Gtk.Entry()
        code_entry.set_placeholder_text(_("Código  del paciente"))
        form_box.append(code_entry)

        # Nombre del paciente
        name_label = Gtk.Label(label=_("Nombre del paciente:"))
        name_label.set_halign(Gtk.Align.START)
        form_box.append(name_label)
        name_entry = Gtk.Entry()
        name_entry.set_placeholder_text(_("Nombre del paciente"))
        form_box.append(name_entry)

        # Apellido del paciente
        surname_label = Gtk.Label(label=_("Apellido del paciente:"))
        surname_label.set_halign(Gtk.Align.START)
        form_box.append(surname_label)
        surname_entry = Gtk.Entry()
        surname_entry.set_placeholder_text(_("Apellido del paciente"))
        form_box.append(surname_entry)

        # Centrar los botones
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        button_box.set_halign(Gtk.Align.CENTER)
        button_box.set_margin_top(32)
        form_box.append(button_box)

        # Botón "Cancelar"
        cancel_button = Gtk.Button(label=_("Cancelar"))
        cancel_button.connect("clicked", lambda w: dialog.destroy())
        button_box.append(cancel_button)

        # Botón "Añadir"
        add_button = Gtk.Button(label=_("Añadir"))
        add_button.connect("clicked", lambda w: self._on_add_patient_dialog_response(dialog, code_entry, name_entry, surname_entry))
        button_box.append(add_button)

        dialog.show()

    # Maneja la respuesta del diálogo de añadir paciente
    def _on_add_patient_dialog_response(self, dialog, code_entry, name_entry, surname_entry):
        code = code_entry.get_text().strip()
        name = name_entry.get_text().strip()
        surname = surname_entry.get_text().strip()

        # Verificar que todos los campos estén rellenados
        if not code or not name or not surname:
            self.show_message(_("Todos los campos son obligatorios."))
            return  # No cerrar el diálogo
        
        # Preparar los datos del paciente
        patient_data = {
            _("code"): code,
            _("name"): name,
            _("surname"): surname
        }

        # Aquí añades el paciente y cierras el diálogo solo si todo es correcto
        self.handler.on_add_patient(patient_data)
        dialog.destroy()  # Cierra el diálogo solo si los datos son válidos
        


    """VISTA DE LOS DETALLES DEL PACIENTE (MEDICAMENTOS)"""
    # Método para establecer los medicamentos en el ListBox
    def set_medications(self, medications: list) -> None:
        self.medication_data.remove_all()  # Limpiar la lista actual
        for medication in medications:
            # Añadir cada medicamento a la lista
            self.medication_data.append(GMedication(medication.id, medication.name, medication.dosage,
                                                    medication.start_date, medication.treatment_duration, medication.patient_id))

    # Muestra la información de un paciente
    def show_patient_details(self, patient, medications):
        """
        Muestra una nueva ventana con los detalles del paciente, incluyendo su lista de medicamentos
        y un botón para eliminar el paciente.
        """
        # Crear una nueva ventana
        details_window = Gtk.Window(title=_("DETALLES PACIENTE"), hexpand=True, vexpand=True)
        details_window.set_default_size(1500, 1000) 
        details_window.connect("destroy", lambda w: self.window.show())  # Volver a mostrar la ventana principal
       

        # Contenedor principal vertical
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        main_box.set_halign(Gtk.Align.CENTER)
        main_box.set_valign(Gtk.Align.CENTER)
        main_box.set_size_request(500, -1)  #anchura, altura
        details_window.set_child(main_box)  # Usar set_child en lugar de add

        # Botón para volver atrás
        back_button = Gtk.Button.new_from_icon_name("pan-start-symbolic")
        back_button.set_halign(Gtk.Align.START)
        back_button.set_valign(Gtk.Align.START)
        back_button.set_margin_top(16)
        back_button.set_margin_start(16)
        back_button.connect("clicked", lambda w: (details_window.destroy(), self.window.show()))
        main_box.append(back_button)

        # Título de la ventana 
        title_label = Gtk.Label(label=f"{patient.code} - {patient.name} {patient.surname}")
        title_label.set_markup(f"<span font='30'>{patient.code} - {patient.name} {patient.surname}</span>")  # Cambiar el tamaño del texto
        
        title_label.set_margin_bottom(32)
        main_box.append(title_label)

        #Subtitulo
        subtitle_label = Gtk.Label(label="MEDICAMENTOS")
        subtitle_label.set_markup("<span size='xx-large'>MEDICAMENTOS</span>")  # Cambiar el tamaño del texto
        subtitle_label.set_margin_bottom(16)
        main_box.append(subtitle_label)

        # Encabezado de la lista de pacientes
        header_label = Gtk.Label(label="Medicamento", hexpand=True, halign=Gtk.Align.CENTER)
        header_label.get_style_context().add_class("header")  # Agregar una clase de estilo para el encabezado
        main_box.append(header_label)  # Añadir el encabezado al contenedor principal

        # Lista medicamentos
        medications_listbox = Gtk.ListBox(hexpand=True, vexpand=True)
        medications_listbox.set_selection_mode(Gtk.SelectionMode.SINGLE)

        # Función para crear cada fila a partir de un elemento de la lista
        def on_create_row(item: GMedication, user_data: Any) -> Gtk.Widget:
            label_name = Gtk.Label(label=item.name, hexpand=True, halign=Gtk.Align.CENTER)
            return label_name

        self.handler.on_load_medications(patient.id)
        
        # Se une el modelo a la lista
        medications_listbox.bind_model(self.medication_data, on_create_row, None)
        medications_listbox.connect("row-activated", lambda _, row: self._on_medication_clicked(self.medication_data[row.get_index()]))

        main_box.append(medications_listbox)
        
        # Botón para añadir medicamento
        add_medication_button = Gtk.Button(label=_("Añadir Medicamento"))
        add_medication_button.set_halign(Gtk.Align.CENTER)
        add_medication_button.set_margin_top(30)
        add_medication_button.connect("clicked", self._on_add_medication_button_clicked, patient.id)
        main_box.append(add_medication_button)

        # Botón para eliminar paciente
        delete_patient_button = Gtk.Button(label=_("Eliminar Paciente"))
        delete_patient_button.set_halign(Gtk.Align.CENTER)
        delete_patient_button.get_style_context().add_class("destructive-action")
        delete_patient_button.connect("clicked", self._on_delete_patient_button_clicked, patient.id, details_window)
        main_box.append(delete_patient_button)

        # Mostrar la nueva ventana
        details_window.show()

    # Maneja el evento de clic en 'Añadir Medicamento'
    def _on_add_medication_button_clicked(self, button: Gtk.Button, patient_id: int) -> None:
        dialog = Gtk.Dialog(title=_("Añadir Medicamento"), transient_for=self.window, modal=True)
        dialog.set_default_size(800, 500)

        content_box = dialog.get_content_area()
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        main_box.set_halign(Gtk.Align.CENTER)
        main_box.set_valign(Gtk.Align.CENTER)
        main_box.set_margin_top(80)
        main_box.set_size_request(700, -1)
        content_box.append(main_box)

        form_box = Gtk.Grid()
        form_box.set_column_spacing(16)
        form_box.set_row_spacing(16)
        main_box.append(form_box)

        name_entry = Gtk.Entry()
        name_label = Gtk.Label(label=_("Nombre del medicamento:"))
        name_label.set_hexpand(True)
        name_label.set_halign(Gtk.Align.START)
        form_box.attach(name_label, 0, 0, 1, 1)
        name_entry.set_placeholder_text(_("Nombre del medicamento"))
        name_entry.set_hexpand(True)
        form_box.attach(name_entry, 0, 1, 1, 1)

        dosage_entry = Gtk.Entry()
        name_label = Gtk.Label(label=_("Dosis:"))
        name_label.set_hexpand(True)
        name_label.set_halign(Gtk.Align.START)
        form_box.attach(name_label, 1, 0, 1, 1)
        dosage_entry.set_placeholder_text(_("Dosis"))
        dosage_entry.set_hexpand(True)
        form_box.attach(dosage_entry, 1, 1, 1, 1)

        start_date_entry = Gtk.Entry()
        start_date_label = Gtk.Label(label=_("Fecha de inicio:"))
        start_date_label.set_hexpand(True)
        start_date_label.set_halign(Gtk.Align.START)
        form_box.attach(start_date_label, 0, 2, 1, 1)
        start_date_entry.set_placeholder_text(_("Fecha de inicio (YYYY-MM-DD)"))
        start_date_entry.set_hexpand(True)
        form_box.attach(start_date_entry, 0, 3, 1, 1)

        duration_entry = Gtk.Entry()
        duration_label = Gtk.Label(label=_("Duración del tratamiento:"))
        duration_label.set_hexpand(True)
        duration_label.set_halign(Gtk.Align.START)
        form_box.attach(duration_label, 1, 2, 1, 1)
        duration_entry.set_placeholder_text(_("Duración del tratamiento (días)"))
        duration_entry.set_hexpand(True)
        form_box.attach(duration_entry, 1, 3, 1, 1)

        posology_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        posology_box.set_halign(Gtk.Align.CENTER)
        posology_box.set_valign(Gtk.Align.CENTER)
        posology_box.set_size_request(700, -1)
        main_box.append(posology_box)

        posology_entry = Gtk.Entry()
        posology_label = Gtk.Label(label=_("Posologías:"))
        posology_label.set_margin_bottom(-8)
        posology_label.set_halign(Gtk.Align.START)
        posology_box.append(posology_label)

        posology_entry.set_placeholder_text(_("Posologías (HH:MM separadas por comas)"))
        posology_box.append(posology_entry)


        # Centrar los botones
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        button_box.set_halign(Gtk.Align.CENTER)
        button_box.set_margin_top(32)
        main_box.append(button_box)

        # Botón "Cancelar"
        cancel_button = Gtk.Button(label=_("Cancelar"))
        cancel_button.connect("clicked", lambda w: dialog.response(Gtk.ResponseType.CANCEL))
        button_box.append(cancel_button)

        # Botón "Añadir"
        add_button = Gtk.Button(label=_("Añadir"))
        add_button.connect("clicked", lambda w: dialog.response(Gtk.ResponseType.OK))
        button_box.append(add_button)


        dialog.connect("response", self._on_add_medication_dialog_response, patient_id, name_entry, dosage_entry, start_date_entry, duration_entry, posology_entry)
        dialog.show()


    # Maneja la respuesta del diálogo de añadir medicamento
    def _on_add_medication_dialog_response(self, dialog, response_id, patient_id, name_entry, dosage_entry, start_date_entry, duration_entry, posology_entry):
        if response_id == Gtk.ResponseType.OK:
            try:
                # Recoger y validar los datos del medicamento
                medication_data = {
                    "name": name_entry.get_text().strip(),
                    "dosage": float(dosage_entry.get_text().strip()),
                    "start_date": start_date_entry.get_text().strip(),
                    "treatment_duration": int(duration_entry.get_text().strip())
                }

                # Procesar y validar las posologías
                posology_text = posology_entry.get_text().strip()
                posology_data = []

                if posology_text:
                    posology_data = [
                        {
                            "time": f"{time.split(':')[0]}:{time.split(':')[1]}",
                            "quantity": 1.0,
                            "hour": int(time.split(":")[0]),
                            "minute": int(time.split(":")[1]),
                            "id": None
                        }
                        for time in posology_text.split(",") if ":" in time
                    ]

                # Añadir el nuevo medicamento y obtener su ID
                medication_id = self.handler.on_add_medication(patient_id, medication_data)

                # Agregar las posologías al nuevo medicamento
                for posology in posology_data:
                    self.handler.on_add_posology(patient_id, medication_id, posology)

                # Actualizar la lista de medicamentos del paciente
                self.handler.on_load_medications(patient_id)

                # Cerrar el diálogo solo si todo fue exitoso
                dialog.hide()
                GLib.idle_add(dialog.destroy)  # Asegurar que el diálogo se destruye de forma segura

            except ValueError as e:
                self.show_message(_("Error en los datos ingresados: {}").format(str(e)))
                # No cerrar el diálogo si hay un error en los datos
        else:
            # Si el usuario cancela, también cerramos el diálogo
            dialog.hide()
            GLib.idle_add(dialog.destroy)  # Asegurar que el diálogo se destruye de forma segura
            

    # Maneja el evento de clic en el botón "Eliminar Paciente"
    def _on_delete_patient_button_clicked(self, button, patient_id, pat_dialog):
        dialog = Gtk.MessageDialog(
            transient_for=self.window,
            modal=True,
            message_type=Gtk.MessageType.WARNING,
            buttons=Gtk.ButtonsType.OK_CANCEL,
            text=_("¿Está seguro de que desea eliminar este paciente?"),
            secondary_text=_("Esta acción no se puede deshacer.")
        )
        
        dialog.connect("response", self._on_delete_patient_dialog_response, patient_id, pat_dialog)
        dialog.present()

    # Maneja la respuesta del diálogo de confirmación para eliminar un paciente
    def _on_delete_patient_dialog_response(self, dialog, response, patient_id, pat_dialog):
        """
        Maneja la respuesta del diálogo de confirmación para eliminar un paciente.
        """
        if response == Gtk.ResponseType.OK:
            self.handler.on_delete_patient(patient_id)
            pat_dialog.destroy()
            self.window.show()
        dialog.destroy()


   
    # Maneja el evento del clic en un medicamento
    def _on_medication_clicked(self, medication):
        self.show_medication_details(medication.patient_id, medication)


    """ VISTA DE LOS DETALLES DE LOS MEDICAMENTOS Y SUS POSOLOGÍAS"""
   # Muestra los detalles de un medicamento
    def show_medication_details(self, patient_id, medication):
        dialog = Gtk.Dialog(title=_("Detalles del medicamento"), transient_for=self.window, modal=True)
        dialog.set_default_size(800, 500)

        content_box = dialog.get_content_area()
        form_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        form_box.set_halign(Gtk.Align.CENTER)
        form_box.set_valign(Gtk.Align.CENTER)
        form_box.set_margin_top(32)
        form_box.set_margin_start(32)
        form_box.set_margin_end(32)
        form_box.set_size_request(600, -1)
        content_box.append(form_box)

        # Contenedor para el botón "Volver" y el título
        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        title_box.set_hexpand(True)
        title_box.set_margin_top(32)
        form_box.append(title_box)

        # Titulo
        title_label = Gtk.Label(label=f"{medication.name}")
        title_label.set_markup(f"<span size='xx-large'>{medication.name}</span>")
        title_label.set_halign(Gtk.Align.START)
        title_box.append(title_label)  # Añadir el título al contenedor

        # Espaciador para empujar el botón "Volver" a la derecha
        title_box.append(Gtk.Box(hexpand=True))

        # Botón "Volver" alineado con el título
        back_button = Gtk.Button.new_from_icon_name("pan-start-symbolic")
        back_button.set_halign(Gtk.Align.END)
        back_button.connect("clicked", lambda w: dialog.destroy())  # Cerrar el diálogo
        title_box.append(back_button)

        # Información del medicamento
        dosage_label = Gtk.Label(label=_("Dosis: {}").format(medication.dosage))
        dosage_label.set_halign(Gtk.Align.START)
        form_box.append(dosage_label)

        start_date_label = Gtk.Label(label=_("Fecha de inicio: {}").format(medication.start_date))
        start_date_label.set_halign(Gtk.Align.START)
        form_box.append(start_date_label)

        duration_label = Gtk.Label(label=_("Duración del tratamiento: {} días").format(medication.treatment_duration))
        duration_label.set_halign(Gtk.Align.START)
        form_box.append(duration_label)

        # Subtitulo
        posology_title_label = Gtk.Label(label=_("Posologías"))
        posology_title_label.set_markup("<span font='18'>Posologías</span>")
        posology_title_label.set_halign(Gtk.Align.START)
        posology_title_label.set_margin_top(16)
        form_box.append(posology_title_label)

        # Mostrar las posologías
        posologies = self.handler.list_posologies(patient_id, medication.id)
        if not posologies:
            no_posologies_label = Gtk.Label(label=_("No hay posologías asignadas."))
            form_box.append(no_posologies_label)
        else:
            for posology in posologies:
                posology_label = Gtk.Label(label=f"{posology.hour}:{posology.minute}")
                posology_label.set_margin_bottom(-8)
                posology_label.set_halign(Gtk.Align.START)
                form_box.append(posology_label)

        # Centrar los botones
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        button_box.set_halign(Gtk.Align.CENTER)
        button_box.set_margin_top(32)
        form_box.append(button_box)

        # Botón "Editar"
        edit_button = Gtk.Button(label=_("Editar"))
        edit_button.set_margin_bottom(32)
        edit_button.connect("clicked", self._on_edit_medication_button_clicked, medication, posologies, dialog)
        button_box.append(edit_button)

        dialog.show()


    # Maneja el evento de clic en 'Editar Medicamento'
    def _on_edit_medication_button_clicked(self, button, medication, posologies, med_dialog):
        self._on_edit_medication_dialog(medication.patient_id, medication, posologies, med_dialog)


    # Maneja el cuadro de diálogo de edición de medicamentos
    def _on_edit_medication_dialog(self, patient_id: int, medication=None, posologies=None, med_dialog=None):
        dialog = Gtk.Dialog(title=_("Editar Medicamento"), transient_for=self.window, modal=True)
        dialog.set_default_size(800, 500)

        content_box = dialog.get_content_area()
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        main_box.set_halign(Gtk.Align.CENTER)
        main_box.set_valign(Gtk.Align.CENTER)
        main_box.set_margin_top(80)
        main_box.set_size_request(700, -1)
        content_box.append(main_box)

        form_box = Gtk.Grid()
        form_box.set_column_spacing(16)
        form_box.set_row_spacing(16)
        main_box.append(form_box)

        name_entry = Gtk.Entry()
        name_label = Gtk.Label(label=_("Nombre del medicamento:"))
        name_label.set_hexpand(True)
        name_label.set_halign(Gtk.Align.START)
        form_box.attach(name_label, 0, 0, 1, 1)
        name_entry.set_placeholder_text(_("Nombre del medicamento"))
        name_entry.set_hexpand(True)
        form_box.attach(name_entry, 0, 1, 1, 1)

        dosage_entry = Gtk.Entry()
        name_label = Gtk.Label(label=_("Dosis:"))
        name_label.set_hexpand(True)
        name_label.set_halign(Gtk.Align.START)
        form_box.attach(name_label, 1, 0, 1, 1)
        dosage_entry.set_placeholder_text(_("Dosis"))
        dosage_entry.set_hexpand(True)
        form_box.attach(dosage_entry, 1, 1, 1, 1)

        start_date_entry = Gtk.Entry()
        start_date_label = Gtk.Label(label=_("Fecha de inicio:"))
        start_date_label.set_hexpand(True)
        start_date_label.set_halign(Gtk.Align.START)
        form_box.attach(start_date_label, 0, 2, 1, 1)
        start_date_entry.set_placeholder_text(_("Fecha de inicio (YYYY-MM-DD)"))
        start_date_entry.set_hexpand(True)
        form_box.attach(start_date_entry, 0, 3, 1, 1)

        duration_entry = Gtk.Entry()
        duration_label = Gtk.Label(label=_("Duración del tratamiento:"))
        duration_label.set_hexpand(True)
        duration_label.set_halign(Gtk.Align.START)
        form_box.attach(duration_label, 1, 2, 1, 1)
        duration_entry.set_placeholder_text(_("Duración del tratamiento (días)"))
        duration_entry.set_hexpand(True)
        form_box.attach(duration_entry, 1, 3, 1, 1)

        posology_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        posology_box.set_halign(Gtk.Align.CENTER)
        posology_box.set_valign(Gtk.Align.CENTER)
        posology_box.set_size_request(700, -1)
        main_box.append(posology_box)

        posology_entry = Gtk.Entry()
        posology_label = Gtk.Label(label=_("Posologías:"))
        posology_label.set_margin_bottom(-8)
        posology_label.set_halign(Gtk.Align.START)
        posology_box.append(posology_label)

        posology_entry.set_placeholder_text(_("Posologías (HH:MM separadas por comas)"))
        posology_box.append(posology_entry)

        if medication:
            name_entry.set_text(medication.name)
            dosage_entry.set_text(str(medication.dosage))
            start_date_entry.set_text(medication.start_date)
            duration_entry.set_text(str(medication.treatment_duration))

        if posologies:
            posology_texts = [f"{posology.hour}:{posology.minute}" for posology in posologies]
            posology_entry.set_text(", ".join(posology_texts))


        # Centrar los botones
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        button_box.set_halign(Gtk.Align.CENTER)
        button_box.set_margin_top(32)
        main_box.append(button_box)

        # Botón "Cancelar"
        cancel_button = Gtk.Button(label=_("Cancelar"))
        cancel_button.connect("clicked", lambda w: dialog.response(Gtk.ResponseType.CANCEL))
        button_box.append(cancel_button)

        # Botón "Guardar"
        save_button = Gtk.Button(label=_("Guardar"))
        save_button.connect("clicked", lambda w: dialog.response(Gtk.ResponseType.OK))
        button_box.append(save_button)

        # Botón "Eliminar"
        delete_button = Gtk.Button(label=_("Eliminar"))
        delete_button.get_style_context().add_class("destructive-action")
        delete_button.set_halign(Gtk.Align.CENTER)
        delete_button.connect("clicked", self._on_delete_medication_button_clicked, medication.patient_id, medication.id, dialog, med_dialog)
        main_box.append(delete_button)

        dialog.connect("response", self._on_edit_medication_dialog_response, patient_id, name_entry, dosage_entry, start_date_entry, duration_entry, posology_entry, medication, med_dialog)
        dialog.show()

    # Maneja la respuesta del diálogo de edición de medicamentos
    def _on_edit_medication_dialog_response(self, dialog, response_id, patient_id, name_entry, dosage_entry, start_date_entry, duration_entry, posology_entry, existing_medication, med_dialog):
        if response_id == Gtk.ResponseType.OK:
            try:
                # Validar y obtener los datos del medicamento
                medication_data = {
                    "name": name_entry.get_text().strip(),
                    "dosage": float(dosage_entry.get_text().strip()),
                    "start_date": start_date_entry.get_text().strip(),
                    "treatment_duration": int(duration_entry.get_text().strip())
                }

                # Actualizar el medicamento
                self.handler.on_update_medication(patient_id, existing_medication.id, medication_data)

                # Obtener y validar las nuevas posologías
                posology_text = posology_entry.get_text().strip()
                new_posologies = []
                if posology_text:
                    new_posologies = [
                        {
                            "time": f"{int(time.split(':')[0]):02d}:{int(time.split(':')[1]):02d}",
                            "hour": int(time.split(":")[0]),
                            "minute": int(time.split(":")[1]),
                            "quantity": 1.0  # Valor por defecto si es necesario
                        }
                        for time in posology_text.split(",") if ":" in time
                    ]

                # Obtener las posologías existentes
                existing_posologies = self.handler.list_posologies(patient_id, existing_medication.id)

                # Eliminar todas las posologías existentes
                for posology in existing_posologies:
                    self.handler.on_delete_posology(patient_id, existing_medication.id, posology.id)

                # Agregar las nuevas posologías
                for posology in new_posologies:
                    self.handler.on_add_posology(patient_id, existing_medication.id, posology)

                # Actualizar la lista de medicamentos
                self.handler.on_load_medications(patient_id)

                # Cerrar el diálogo
                dialog.destroy()
                med_dialog.destroy()

                # Mostrar mensaje de éxito después de cerrar el diálogo
                #GLib.idle_add(self.show_success_message, _("Se han guardado los cambios correctamente"))

            except ValueError as e:
                self.show_error_message(_("Error en los datos ingresados: {}").format(str(e)))
        else:
            dialog.hide()

        # Asegurar que el diálogo se destruye después de todas las operaciones
        GLib.idle_add(dialog.destroy)

    def show_success_message(self, message):
        dialog = Gtk.MessageDialog(
            transient_for=self.window,
            modal=True,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text=message
        )
        dialog.connect("response", lambda d, r: d.destroy())
        dialog.show()

    def show_error_message(self, message):
        dialog = Gtk.MessageDialog(
            transient_for=self.window,
            modal=True,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text=message
        )
        dialog.connect("response", lambda d, r: d.destroy())
        dialog.show()
        

    # Maneja el evento de clic en 'Eliminar Medicamento' en la pestaña de Editar Medicamento
    def _on_delete_medication_button_clicked(self, button, patient_id, medication_id, edit_dialog, med_dialog):
        dialog = Gtk.MessageDialog(
            transient_for=self.window,
            modal=True,
            message_type=Gtk.MessageType.WARNING,
            buttons=Gtk.ButtonsType.OK_CANCEL,
            text=_("¿Está seguro de que desea eliminar este medicamento?"),
            secondary_text=_("Esta acción no se puede deshacer.")
        )
    
        dialog.connect("response", self._on_delete_medication_dialog_response, patient_id, medication_id, edit_dialog, med_dialog)
        dialog.present()

    # Maneja la respuesta del diálogo de confirmación para eliminar medicamento en la pestaña de Editar Medicamento
    def _on_delete_medication_dialog_response(self, dialog, response, patient_id, medication_id, edit_dialog, med_dialog):
        if response == Gtk.ResponseType.OK:
            self.handler.on_delete_medication(patient_id, medication_id)
            self.handler.on_load_medications(patient_id)
            dialog.destroy()
            edit_dialog.destroy()
            med_dialog.destroy()
        else:
            dialog.destroy()
        