import { useState, useEffect } from "react";
import sLS from 'react-secure-storage';
import icon from '../../photos/right.png';
import icon2 from '../../photos/next.png';
import { Link } from "react-router-dom";
import Prescription from "../../pages/Doctor/prescriptionForm";

const BookedAppointments = () => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [appointments, setAppointments] = useState([]);
    const [usersData, setUsersData] = useState({});
    const [todayAppointments, setTodayAppointments] = useState([]);
    

    const getUserData = async (email) => {
        try {
            const res = await fetch(`http://localhost:5225/Auth/GetUser?Email=${email}`, {
                method: "GET",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
            });
            if (!res.ok) {
                throw new Error("No user found");
            }
            const userData = await res.json();
            setUsersData(prevData => ({ ...prevData, [email]: userData }));
        } catch (error) {
            console.error('Error fetching user data:', error);
        }
    };

    const fetchEvents = async () => {
        try {
            const response = await fetch('http://localhost:5225/Hospital/Doctor/BookedAppointments', {
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
            data.forEach(appointment => getUserData(appointment.email));
        } catch (error) {
            console.error('Error fetching events:', error);
        }
    };

    const filterTodayAppointments = (appointments) => {
        const today = new Date().toLocaleDateString('en-US', { weekday: 'long' });
        return appointments.filter(appointment => appointment.dayName === today);
    };


    useEffect(() => {
        fetchEvents();
    }, []);

    useEffect(() => {
        const filteredAppointments = filterTodayAppointments(appointments);
        setTodayAppointments(filteredAppointments);
    }, [appointments]);

    const prescriptionForm = document.querySelector('.prescriptionForm');
    
    


    const openPrescriptionForm = () => {
        prescriptionForm.style.display = 'flex';
        

    }

    return (
        <>
            <h3>today's appointments</h3>
            {todayAppointments.length > 0 ? (
                todayAppointments.map(appointment => {
                    const user = usersData[appointment.email];
                    return (
                        <>
                        <div key={appointment.email} className="bACard" onClick={() => openPrescriptionForm()}>
                            {user && <img src={`http://localhost:5225/Image/User/${user.img}`} alt="not found" />}
                            <div className="appointInfo">
                                <h1>{appointment.patientName}</h1>
                                <p>{appointment.dayName} {appointment.from} - {appointment.to}</p>
                            </div>
                            <img className="userAppoint" src={icon} alt="not found" />
                        </div>
                        <Prescription patientEmail={appointment.email} name={appointment.patientName} />
                        </>
                    );
                })
            ) : (
                <p>No appointments for today</p>
            )}
            <div className="showAllAppointments"><Link>view all appoinments <img className="viewAllIcon" src={icon2} alt="not found" /></Link></div> 
        </>
    );
};

export default BookedAppointments;
