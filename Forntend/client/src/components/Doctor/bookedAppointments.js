import React, { useState, useEffect } from 'react';
import sLS from 'react-secure-storage';
import icon2 from '../../photos/next.png';
import { Link } from "react-router-dom";
// import Prescription from "../../pages/Doctor/prescriptionForm";

const BookedAppointments = ({ appointments }) => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [usersData, setUsersData] = useState({});

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

    useEffect(() => {
        appointments.forEach(appointment => {
            getUserData(appointment.email);
        });
    }, [appointments]);

    // const prescriptionForm = document.querySelector('.prescriptionForm');

    // const openPrescriptionForm = () => {
    //     prescriptionForm.style.display = 'flex';
    // };

    return (
        <>
            <h3>Today's Appointments</h3>
            {appointments.length > 0 ? (
                appointments.map(appointment => {
                    const user = usersData[appointment.email];
                    return (
                        <div key={appointment.email} className="bACard">
                            {user && <img src={`http://localhost:5225/Image/User/${user.img}`} alt="User" />}
                            <div className="appointInfo">
                                <h1>{appointment.patientName}</h1>
                                <p>{appointment.from} - {appointment.to}</p>
                            </div>
                            <Link to={`/prescription/${appointment.email}`} className="writeP">Start Session</Link>
                            {/* <Prescription patientEmail={appointment.email} name={appointment.patientName} /> */}
                        </div>
                    );
                })
            ) : (
                <p className="null">No appointments for today</p>
            )}
            <Link className="showAllAppointments" to={'/AllBookedAppointments'}>View All Patients <img className="viewAllIcon" src={icon2} alt="View All" /></Link>
        </>
    );
};

export default BookedAppointments;
