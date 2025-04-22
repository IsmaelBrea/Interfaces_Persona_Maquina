# Diseño Software
## Casos de Uso
- CU-01 Marcar Medicación como Tomada
- CU-02 Desmarcar Medicación como Tomada
- CU-03 Notificar para la Toma de Medicación

## Diseño Estático
```mermaid
classDiagram
    class MedicationProvider {
        -String baseUrl
        -List~Medication~ _medications
        -List~PosologyMed~ _allPosologies
        -List~Intake~ _intakes
        +List~Medication~ medications
        +List~PosologyMed~ allPosologies
        +List~Intake~ intakes
        +fetchMedications(int patientId)
        +fetchAllPosologies(int patientId)
        +fetchIntakes(int patientId)
        +addIntake(Intake intake)
        +removeIntake(int intakeId)
    }
    class MainScreen {
        -int _currentIndex
        -List~Widget~ _screens
        +void _onTabTapped(int index)
        +Widget build(BuildContext)
        +Widget _decideMainScreen()
    }
    class InfoScreen {
        +Widget build(BuildContext)
    }
    class TreatmentScreen {
        +Widget build(BuildContext)
    }
    class WatchScreen {
        +Widget build(BuildContext)
    }
    class Medication {
        +int id
        +String name
        +double dosage
        +String startDate
        +int treatmentDuration
        +int patientId
        +List~Posology~ posologies
    }
    class Posology {
        +int id
        +int hour
        +int minute
        +int medicationId
        +String formattedTime
    }
    class PosologyMed {
        +int id
        +int hour
        +int minute
        +int medicationId
        +String medicationName
        +double dosage
        +bool taken
    }
    class Intake {
        +int id
        +String date
        +int medicationId
        +Intake(int id, String date, int medicationId)
        +factory Intake.fromJson(Map~String, dynamic~ json)
        +Map~String, dynamic~ toJson()
    }
    class MyApp {
        +Widget build(BuildContext)
    }
 
    MedicationProvider "1" --> "0..*" Medication : manages
    MedicationProvider "1" --> "0..*" PosologyMed : manages
    MedicationProvider "1" --> "0..*" Intake : manages
    Medication "1" --> "0..*" Posology : contains
    MedicationProvider "1" --> "1" InfoScreen : provides data
    MedicationProvider "1" --> "1" TreatmentScreen : provides data
    MedicationProvider "1" --> "1" WatchScreen : provides data
    MainScreen "1" --> "1" InfoScreen : may contain
    MainScreen "1" --> "1" TreatmentScreen : may contain
    MainScreen "1" --> "1" WatchScreen : may contain
    MyApp "1" --> "1" MainScreen : starts with
    MyApp "1" --> "1" MedicationProvider : provides
```

## Diseño Dinámico
```mermaid
sequenceDiagram
    autonumber

    actor User as Usuario
    participant MyApp as MyApp
    participant MainScreen as MainScreen
    participant TreatmentScreen as TreatmentScreen
    participant InfoScreen as InfoScreen
    participant WatchScreen as WatchScreen
    participant MedicationProvider as Provider
    participant Medication as medication
    participant Posology as posologies
    participant Intake as intakes
    participant NotificationService as Servicio Notificaciones

    User->>MyApp: Abre la aplicación
    MyApp->>MainScreen: Inicia MainScreen
    MainScreen->>MainScreen: Determina el tamaño de la pantalla
    alt Pantalla de móvil
        MainScreen->>TreatmentScreen: Muestra TreatmentScreen como principal
    else Pantalla de reloj
        MainScreen->>WatchScreen: Muestra WatchScreen como única pantalla
    end
    
    alt Pantalla de móvil
        par Carga concurrente de datos
            TreatmentScreen->>MedicationProvider: Solicita lista de posologías
            MedicationProvider->>Posology: GET /patients/{patientId}/posologies
            Posology-->>MedicationProvider: Devuelve lista de posologías (JSON)
            MedicationProvider-->>TreatmentScreen: Notifica cambios en la lista de posologías
            TreatmentScreen-->>User: Muestra lista de tomas diarias
        and
            TreatmentScreen->>MedicationProvider: Solicita lista de intakes
            MedicationProvider->>Intake: GET /patients/{patientId}/intakes
            Intake-->>MedicationProvider: Devuelve lista de intakes (JSON)
            MedicationProvider-->>TreatmentScreen: Notifica cambios en la lista de intakes
        end
    else Pantalla de reloj
        WatchScreen->>MedicationProvider: Solicita lista de posologías
        MedicationProvider->>Posology: GET /patients/{patientId}/posologies
        Posology-->>MedicationProvider: Devuelve lista de posologías (JSON)
        MedicationProvider-->>WatchScreen: Notifica cambios en la lista de posologías
        WatchScreen-->>User: Muestra lista de tomas diarias
    end

    alt Error de conexión/servidor en cualquier solicitud
        Posology-->>MedicationProvider: Error de conexión/servidor
        Intake-->>MedicationProvider: Error de conexión/servidor
        MedicationProvider-->>TreatmentScreen: Notifica error
        TreatmentScreen-->>User: Muestra mensaje de error y opción de reintentar
    end

    alt Pantalla de móvil
        User->>TreatmentScreen: Clic en una toma de medicamento
        TreatmentScreen->>MedicationProvider: Marca la toma como "tomada"
    else Pantalla de reloj
        User->>WatchScreen: Clic en una toma de medicamento
        WatchScreen->>MedicationProvider: Marca la toma como "tomada"
    end
    MedicationProvider->>Intake: POST /intakes
    alt Conexión exitosa
        Intake-->>MedicationProvider: Confirma creación de Intake
        MedicationProvider-->>TreatmentScreen: Actualiza estado de la toma
        TreatmentScreen-->>User: Muestra toma en verde (no se puede cambiar)
    else Error de conexión/servidor
        Intake-->>MedicationProvider: Error de conexión/servidor
        MedicationProvider-->>TreatmentScreen: Notifica error
        TreatmentScreen-->>User: Muestra mensaje de error y opción de reintentar
    end

    alt Pantalla de móvil
        User->>MainScreen: Clic en botón "Información" en la barra de navegación
        MainScreen->>InfoScreen: Cambia a InfoScreen
        InfoScreen->>MedicationProvider: Solicita lista de medicamentos
        MedicationProvider->>Medication: GET /patients/{patientId}/medications
        alt Conexión exitosa
            Medication-->>MedicationProvider: Devuelve lista de medicamentos (JSON)
            MedicationProvider-->>InfoScreen: Notifica cambios en la lista
            InfoScreen-->>User: Muestra lista de medicamentos con desplegables
        else Error de conexión/servidor
            Medication-->>MedicationProvider: Error de conexión/servidor
            MedicationProvider-->>InfoScreen: Notifica error
            InfoScreen-->>User: Muestra mensaje de error y opción de reintentar
        end

        User->>InfoScreen: Clic en flecha de desplegable de un medicamento
        InfoScreen-->>User: Muestra detalles del medicamento (dosis, horarios, etc.)

        User->>InfoScreen: Clic en icono de campana para activar notificación
        InfoScreen->>NotificationService: Programar notificaciones de aviso (5 min antes)
        alt Notificación programada con éxito
            NotificationService-->>User: Confirma activación de notificación
            NotificationService-->>MedicationProvider: Guarda el estado de notificación activada
        else Error al programar notificación
            NotificationService-->>User: Muestra mensaje de error y opción de reintentar
        end

        User->>MainScreen: Clic en botón "Tratamiento" en la barra de navegación
        MainScreen->>TreatmentScreen: Vuelve a TreatmentScreen
    end

    loop Actualización periódica (cada 5 minutos)
        alt Pantalla de móvil
            TreatmentScreen->>MedicationProvider: Solicita actualizaciones de intakes
        else Pantalla de reloj
            WatchScreen->>MedicationProvider: Solicita actualizaciones de intakes
        end
        MedicationProvider->>Intake: GET /patients/{patientId}/intakes?since=lastUpdate
        alt Nuevos datos disponibles
            Intake-->>MedicationProvider: Devuelve nuevos intakes (JSON)
            alt Pantalla de móvil
                MedicationProvider-->>TreatmentScreen: Actualiza la lista de tomas
                TreatmentScreen-->>User: Actualiza la interfaz si es necesario
            else Pantalla de reloj
                MedicationProvider-->>WatchScreen: Actualiza la lista de tomas
                WatchScreen-->>User: Actualiza la interfaz si es necesario
            end
        else Sin cambios
            Intake-->>MedicationProvider: Respuesta 304 (Sin cambios)
        else Error de conexión/servidor
            Intake-->>MedicationProvider: Error de conexión/servidor
            MedicationProvider-->>TreatmentScreen: Notifica error
            TreatmentScreen-->>User: Muestra mensaje de error discreto
        end
    end
```
