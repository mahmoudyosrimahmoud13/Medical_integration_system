import editIcon from '../../photos/pen.png';
import delIcon from '../../photos/x-button.png';
import { useState, useEffect } from 'react';
import sLS from 'react-secure-storage';


const PatientAppointments = () => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [appointments, setAppointments] = useState([]);


    const fetchEvents = async () => {
        try {
            const response = await fetch('http://localhost:5225/Hospital/Patient/GetPatientDates', {
                method: "GET",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
            });
            if (!response.ok) {
                throw new Error('Failed to fetch events');
            }
            const data = await response.json();
            setAppointments(data);
        } catch (error) {
            console.error('Error fetching events:', error);
        }
    };
    

    useEffect(() => {
        fetchEvents();
    }, []);
    return(
        <>
            <div className='paientAppointments'>
                <h1>your appointments</h1>
                {appointments.length > 0 ? (
                    appointments.map(appointment => (
                        <div key={appointment.doctorId}>
                        <p className='day'>{appointment.dayName} {appointment.date}</p>
                        <div className="patientACard">
                            <div className="appointInfo">
                                <p>{appointment.doctorName}, {appointment.doctorSpecialty}, {appointment.areaName} {appointment.from} - {appointment.to}</p>
                            </div>
                            <div className='showIcons'>
                                <img src={editIcon} alt='not found' />
                                <img src={delIcon} alt='not found' />
                            </div>
                        </div>
                        </div>
                ))) : (<p>no appointments</p>)}
            </div>
        </>
    )
}

export default PatientAppointments;