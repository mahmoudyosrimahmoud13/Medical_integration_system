import editIcon from '../../photos/pen.png';
import delIcon from '../../photos/x-button.png';
import { useState, useEffect } from 'react';
import sLS from 'react-secure-storage';
import Swal from 'sweetalert2';
import image from '../../photos/pngaaa.com-3670877.png';

const PatientAppointments = () => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [appointments, setAppointments] = useState([]);
    const [from, setValue] = useState('');
    const [day, setValue2] = useState('');
    const [dateID, setDateID] = useState('');
    const [message, setMessage] = useState('');

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
            const today = new Date();
            today.setHours(0, 0, 0, 0); // Set to start of today
            const filteredAppointments = data.filter(appointment => {
                const appointmentDate = new Date(appointment.date);
                appointmentDate.setHours(0, 0, 0, 0); // Set to start of the appointment day
                return appointmentDate >= today;
            });

            setAppointments(filteredAppointments);
        } catch (error) {
            console.error('Error fetching events:', error);
        }
    };

    const deleteDate = async (dateID) => {
        try {
            const response = await fetch(`http://localhost:5225/Hospital/Patient/CancelBookedDate?PaintDateid=${dateID}`, {
                method: "DELETE",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
            });
            if (!response.ok) {
                throw new Error('Failed to fetch events');
            }
            Swal.fire("Deleted!", "Your appointment has been deleted.", "success");
            fetchEvents();
        } 
        catch (error) {
            console.error('Error fetching events:', error);
        }
    };

    const deleteBtn = (dateID, dayName) => {
        const daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        const today = new Date();
        const todayDayName = daysOfWeek[today.getDay()];

        if (dayName === todayDayName) {
            Swal.fire({
                title: "Can't cancel appointment",
                text: "Cancellation must be made not on the same day.",
                icon: "warning",
                confirmButtonText: "OK",
            });
            return;
        }
        Swal.fire({
            title: "Are you sure you want cancel this appointment?",
            icon: "warning",
            showCancelButton: true,
            confirmButtonText: "Yes, cancel it!",
            cancelButtonText: "No",
        }).then((result) => {
            if (result.isConfirmed) {
                deleteDate(dateID);
            } 
        });
    }

    const extractTimeWithAMPM = (time) => {
        const date = new Date(`2000-01-01T${time}`);
        const formattedTime = date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: true });
        return formattedTime;
    }

    const data = { from, day };

    const updateDate = async () => {
        try {
            const res = await fetch(`http://localhost:5225/Hospital/Patient/UpdateBookedDate?PaintDateid=${dateID}`, {
                method: "PUT",
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${convertToken.token}`
                },
                body: JSON.stringify(data)
            });
            if (!res.ok) {
                setMessage('not good');
            }
            else if(res.ok){
                const m = await res.text();
                if(m === 'Save.' || m === 'Save Change'){
                    fetchEvents();
                    cancel();
                }
                else if(m === 'Choose The Appropriate Day' || m === 'Choose The Appropriate Time'){
                    setMessage('! that appointment is not available')
                }
                else{
                    setMessage('! ' + m);
                }
            }
        } 
        catch (error) {
            console.error('Error fetching events:', error);
        }
    };

    let af = document.querySelector('.appForm');

    const showUPrompt = () => {
        af.style.display = 'flex';
    }
    
    const update = () => {
        if(from && day){
            updateDate();
        }
        else{
            setMessage('* fields are required');
        }
    }

    const cancel = () => {
        af.style.display = 'none';
    }

    useEffect(() => {
        fetchEvents();
    }, []);

    return (
        <>
            <div className='patientAppointments'>
                <h1>your appointments</h1>
                {appointments.length > 0 ? (
                    appointments.map(appointment => (
                        <div key={appointment.paientDateId}>
                            <p className='day'>{appointment.dayName} {appointment.date}</p>
                            <div className="patientACard">
                                <div className="appointInfo">
                                    <p>Dr. {appointment.doctorName}, {appointment.doctorSpecialty}, {appointment.areaName} {appointment.from} - {appointment.to}</p>
                                </div>
                                <div className='showIcons'>
                                    <img src={editIcon} alt='not found' onClick={() => {setDateID(appointment.paientDateId); showUPrompt()}} />
                                    <img src={delIcon} alt='not found' onClick={() => deleteBtn(appointment.paientDateId, appointment.dayName)} />
                                </div>
                            </div>
                        </div>
                ))) : (<p className='null'>! there is no appointments</p>)}
            </div>
            <div className="appForm">
                <h2>update your appointment</h2>
                <img src={image} alt="not found" className="form-image" />
                <div className='fo'>
                    <label htmlFor="date">Date:</label>
                    <input type="date" id="appointment-date" name="appointment-time" onChange={(e) => setValue2(e.target.value)} required />
                    
                    <label htmlFor="appointment-time">Appointment Time:</label>
                    <input type="time" id="appointment-time" name="appointment-time" onChange={(e) => setValue(extractTimeWithAMPM(e.target.value))} required />
                    <p className="msg">{message}</p>
                    <div className="button-container">
                        <button className="submit" onClick={() => update()}>submit consultation</button>
                        <button className="cancel" onClick={() => cancel()}>cancel consultation</button>
                    </div>
                </div>
            </div>
        </>
    )
}

export default PatientAppointments;
