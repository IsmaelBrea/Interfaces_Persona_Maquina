const url = "http://127.0.0.1:8000"

let id = null;

// GET
async function getPatientById(id) {
    try{
        const response = await fetch(`${url}/patients/${id}`)
        if (!response.ok) {
            throw new Error(`Error al obtener los datos: ${response.status}`)
        }
        const data = await response.json()
        return data
    } catch (error) {
        console.error("Error: ", error)
        throw error
    }
}

async function getAllPatients() {
    try {
        const response = await fetch(`${url}/patients`);
        if (!response.ok) {
            throw new Error(`Error al obtener los datos: ${response.status}`);
        }
        const data = await response.json();
        return data;
    } catch (error) {
        console.error("Error: ", error);
        throw error;
    }
}

async function getAllMedications(patient) {
    try{
        const response = await fetch(`${url}/patients/${patient}/medications`)
        if (!response.ok) {
            throw new Error(`Error al obtener los datos: ${response.status}`)
        }
        const data = await response.json()
        return data
    } catch (error) {
        console.error("Error: ", error)
        throw error
    }
}

async function getPosologies(patient, medicationId){
    try{
        const response = await fetch(`${url}/patients/${patient}/medications/${medicationId}/posologies`)
        if (!response.ok) {
            throw new Error(`Error al obtener los datos: ${response.status}`)
        }
        const data = await response.json()
        return data
    } catch(error) {
        console.error("Error: ", error)
        throw error
    }
}

async function getAllIntakes(patient, startDate, endDate) {
    try {
        const formattedStartDate = `${startDate}T00:00`;
        const formattedEndDate = `${endDate}T23:59`;
        console.log(`Enviando solicitud: ${url}/patients/${patient}/intakes?start_date=${formattedStartDate}&end_date=${formattedEndDate}`);
        const response = await fetch(`${url}/patients/${patient}/intakes?start_date=${formattedStartDate}&end_date=${formattedEndDate}`);
        if (!response.ok) {
            const errorText = await response.text();
            console.error(`Error response: ${errorText}`);
            throw new Error(`Error al obtener los datos: ${response.status} - ${errorText}`);
        }
        const data = await response.json();
        return data;
    } catch (error) {
        console.error("Error en getAllIntakes: ", error);
        throw error;
    }
}

//Estan agrupadas por medicacion
//Juntar todas y ordenar por fecha para poder filtrar

//Sino obtener las intakes que cumplan con las fechas
//Fecha fin la introducimos en el formulario, sino HOY
//Fecha inicio, HOY - 1 mes, HOY - N dias o la del formulario 

/*************************************************/


// RENDER
async function renderPatientList() {
    try {
        const patients = await getAllPatients();
        const patientListElement = document.getElementById('listaPacientes');
        patientListElement.innerHTML = ''; // Limpiar la lista existente

        patients.forEach(patient => {
            const listItem = document.createElement('li');
            listItem.textContent = `${patient.surname}, ${patient.name} - ${patient.id}`;
            patientListElement.appendChild(listItem);
        });
    } catch (error) {
        console.error("Error al renderizar la lista de pacientes: ", error);
    }
}

async function renderPatient(patientId) {
    try{
        //Limpiar la lista de Medicaciones
        document.getElementById("medicamentos").innerHTML = '';

        if (!patientId) {
            alert("Error, Paciente nulo")
            document.getElementById("infoPaciente").innerHTML = `
                <span class=negrita>Error, Paciente nulo</span>
            `
            document.getElementById("med").style.display = 'none';
            return
        }
        
        const patient = await getPatientById(patientId)

        if(!patient){
            alert("Error, Paciente no encontrado")
            document.getElementById("infoPaciente").innerHTML = `
                <span class=negrita>Error, Paciente no encontrado</span>
            `
            document.getElementById("med").style.display = 'none';
            return
        }

        const medications = await getAllMedications(patientId)

        document.getElementById("med").style.display = 'block';
        
        if(!medications){
            alert("Error, Paciente no encontrado")
            document.getElementById("infoPaciente").innerHTML = `
                <span class=negrita>Error, Medicamentos no encontrados</span>
            `
            return
        }

        
        //Mostrar los datos del Paciente
        document.getElementById("infoPaciente").innerHTML = `
            <div class="fila">
                <span class="negrita">ID:</span>
                <p>${patient.id}</p>
            </div>
            <div class="fila">
                <span class="negrita">Nombre:</span>
                <p>${patient.name}</p>
            </div>
            <div class="fila">
                <span class="negrita">Apellidos:</span>
                <p>${patient.surname}</p>
            </div>
            <div class="fila">
                <span class="negrita">Código:</span>
                <p>${patient.code}</p>
            </div>
        `


        //Mostrar las Medicaciones
        if(medications.length === 0){
            document.getElementById("medicamentos").innerHTML = `
                <p>No hay Medicaciones</p>
            `
            return
        }

        for(const medication of medications){
            const posologies = await getPosologies(patientId, medication.id)
            document.getElementById("medicamentos").innerHTML += `
                <div class="medicamento" role="listitem">
                    <span class="negrita">${medication.name}</span>
                    <div class="fila">
                        <span class="descripcion">Dosis:</span>
                        <p>${medication.dosage} mg</p>
                    </div>
                    <div class="fila">
                        <span class="descripcion">Fecha de Inicio:</span>
                        <p>${medication.start_date}</p>
                    </div>
                    <div class="fila">
                        <span class="descripcion">Duración:</span>
                        <p>${medication.treatment_duration} días</p>
                    </div>
                    <div class="fila">
                        <span class="posologias">Posologías:</span>
                        <p>${posologies.map(posology => `${posology.hour}:${posology.minute.toString().padStart(2, '0')}`).join(", ")}</p>
                    </div>
                </div>
            `
        }
    }catch(error){
        console.error("Error: ", error)
        document.getElementById("med").style.display = 'none';
        document.getElementById("infoPaciente").innerHTML = `
            <span class=negrita>Error, ${error}</span>
        `
    }
}


async function renderMedications() {
    try{
        const patientId = document.getElementById("idPaciente").value

        if (!patientId) {
            alert("Error, Paciente nulo")
            document.getElementById("infoPaciente").innerHTML = `
                <span class=negrita>Error, Paciente nulo</span>
            `
            return
        }
        
        const medications = await getAllMedications(patientId)

        if(!medications){
            alert("Error, Paciente no encontrado")
            document.getElementById("infoPaciente").innerHTML = `
                <span class=negrita>Error, Medicamentos no encontrados</span>
            `
            return
        }

        //Mostrar las Medicaciones
        if(medications.length === 0){
            document.getElementById("medicamentos").innerHTML = `
                <p>No hay Medicaciones</p>
            `
            return
        }

        for(const medication of medications){
            const posologies = await getPosologies(patientId, medication.id)
            document.getElementById("medicamentos").innerHTML += `
                <div class="medicamento" role="listitem">
                    <span class="negrita">${medication.name}</span>
                    <div class="fila">
                        <span class="descripcion">Dosis:</span>
                        <p>${medication.dosage} mg</p>
                    </div>
                    <div class="fila">
                        <span class="descripcion">Fecha de Inicio:</span>
                        <p>${medication.start_date}</p>
                    </div>
                    <div class="fila">
                        <span class="descripcion">Duración:</span>
                        <p>${medication.treatment_duration} días</p>
                    </div>
                    <div class="fila">
                        <span class="posologias">Posologías:</span>
                        <p>${posologies.map(posology => `${posology.hour}:${posology.minute.toString().padStart(2, '0')}`).join(", ")}</p>
                    </div>
                </div>
            `
        }
    }catch(error){
        console.error("Error: ", error)
        document.getElementById("infoPaciente").innerHTML = `
            <span class=negrita>Error, ${error}</span>
        `
    }
}


async function renderReport() {
    try {
        if (!id) {
            alert("Por favor, seleccione un paciente primero");
            
            return;
        }

        const periodoSeleccionado = document.querySelector('input[name="periodo"]:checked').value;
        let startDate, endDate;

        if (periodoSeleccionado === 'ultimoMes') {
            endDate = new Date();
            startDate = new Date();
            startDate.setMonth(startDate.getMonth() - 1);
        } else if (periodoSeleccionado === 'ultimosNDias') {
            const numeroDias = document.getElementById('numeroDias').value;
            if (!numeroDias || isNaN(numeroDias) || numeroDias <= 0) {
                alert("Por favor, ingrese un número válido de días");
                return;
            }
            endDate = new Date();
            startDate = new Date();
            startDate.setDate(startDate.getDate() - parseInt(numeroDias));
        } else if (periodoSeleccionado === 'entreFechas') {
            const fechaInicio = document.getElementById('fechaInicio').value;
            const fechaFin = document.getElementById('fechaFin').value;
            if (!fechaInicio || !fechaFin) {
                alert("Por favor, seleccione ambas fechas");
                return;
            }
            startDate = new Date(fechaInicio);
            endDate = new Date(fechaFin);
            if (startDate > endDate) {
                alert("La fecha de inicio debe ser anterior a la fecha de fin");
                return;
            }
        }

        const startDateString = startDate.toISOString().split('T')[0];
        const endDateString = endDate.toISOString().split('T')[0];

        console.log(`Solicitando tomas para el paciente ${id} desde ${startDateString} hasta ${endDateString}`);

        const intakes = await getAllIntakes(id, startDateString, endDateString);

        if (!intakes || intakes.length === 0) {
            document.getElementById("tomas").innerHTML = `
                <p>No hay tomas en el período seleccionado</p>
            `;
            return;
        }

        // Agrupar todas las tomas por fecha
        const intakesByDate = {};
        for (const medication of intakes) {
            const posologies = await getPosologies(id, medication.id);
            medication.intakes_by_medication.forEach(intake => {
                const intakeDate = new Date(intake.date);
                const dateString = intakeDate.toLocaleDateString();
                if (!intakesByDate[dateString]) {
                    intakesByDate[dateString] = [];
                }

                // Comparar la hora de la toma con la hora de la posología correspondiente
                const intakeTime = intakeDate.getTime();
                let colorClass = 'text-red-500'; // Por defecto, rojo

                for (const posology of posologies) {
                    const posologyTime = new Date(intakeDate);
                    posologyTime.setHours(posology.hour, posology.minute, 0, 0);

                    if (Math.abs(intakeTime - posologyTime.getTime()) <= 15 * 60 * 1000) {
                        colorClass = 'text-green-500'; // Dentro de los 15 minutos, verde
                        break;
                    }
                }

                intakesByDate[dateString].push({
                    medicationName: medication.name,
                    intakeTime: intakeDate,
                    colorClass: colorClass
                });
            });
        }

        // Ordenar las fechas
        const sortedDates = Object.keys(intakesByDate).sort((a, b) => a.intakeDate - b.intakeDate);

        let tomasHTML = '';

        sortedDates.forEach(dateString => {
            tomasHTML += `<div class="toma"><span class="negrita">${dateString}:</span>`;
            
            // Ordenar las tomas del día por hora
            const sortedIntakes = intakesByDate[dateString].sort((a, b) => a.intakeTime - b.intakeTime);
            
            sortedIntakes.forEach(intake => {
            tomasHTML += `
                <p>· ${intake.medicationName} - <span class="${intake.colorClass}">${intake.intakeTime.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}${intake.colorClass === 'text-red-500' ? ' *' : ''}</span></p>
            `;
            });

            tomasHTML += `</div>`;
        });

        document.getElementById("tomas").innerHTML = tomasHTML;
    } catch (error) {
        console.error("Error en renderReport: ", error);
        document.getElementById("tomas").innerHTML = `
            <span class="negrita">Error: ${error.message || 'Ocurrió un error al obtener las tomas'}</span>
        `;
    }
}


// Filtrar la lista de pacientes
function filterPatientList() {
    const searchTerm = document.getElementById("idPaciente").value.toLowerCase();
    const patientListElement = document.getElementById('listaPacientes');
    const patients = patientListElement.getElementsByTagName('li');

    for (let patient of patients) {
        const patientName = patient.textContent.toLowerCase();
        if (patientName.includes(searchTerm)) {
            patient.style.display = "";
        } else {
            patient.style.display = "none";
        }
    }
}

document.getElementById('listaPacientes').addEventListener('click', async (event) => {
    if (event.target.tagName === 'LI') {
        const patientId = event.target.textContent.split(' - ')[1];
        id = patientId;
        await renderPatient(patientId);
    }
});


//Mostrar Formulario Informe
document.getElementById('ultimoMes').addEventListener('change', (event) => {
    document.querySelector('.nDias').style.display = 'none';
    document.querySelector('.eFechas').style.display = 'none';
});

document.getElementById('ultimosNDias').addEventListener('change', () => {
    document.querySelector('.nDias').style.display = 'block';
    document.querySelector('.eFechas').style.display = 'none';
});

document.getElementById('entreFechas').addEventListener('change', () => {
    document.querySelector('.nDias').style.display = 'none';
    document.querySelector('.eFechas').style.display = 'flex';
});


// Llamar a la función para renderizar la lista de pacientes cuando se cargue la página
document.addEventListener('DOMContentLoaded', renderPatientList);

// Agregar event listener al input de búsqueda
document.getElementById("idPaciente").addEventListener("input", filterPatientList);

// Eliminar el envio del formulario con enter
document.getElementById("idPaciente").addEventListener("keydown", function(event) {
    if (event.key === "Enter") {
        event.preventDefault();
    }
});

// Agregar event listener al botón de búsqueda de informe
document.querySelector(".buscadorInforme form").addEventListener("submit", function(event) {
    event.preventDefault();
    renderReport();
});