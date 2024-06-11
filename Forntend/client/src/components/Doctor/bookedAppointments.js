import React, { useState, useEffect } from 'react';
import sLS from 'react-secure-storage';
import icon2 from '../../photos/next.png';
import { Link } from "react-router-dom";

const BookedAppointments = ({ appointments }) => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [usersData, setUsersData] = useState({});
    const [currentPage, setCurrentPage] = useState(0);
    const appointmentsPerPage = 1;

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

    // Sort appointments based on 'from' time
    const sortedAppointments = [...appointments].sort((a, b) => {
        return a.from.localeCompare(b.from);
    });

    const handlePageClick = (index) => {
        setCurrentPage(index);
    };

    const offset = currentPage * appointmentsPerPage;
    const currentAppointments = sortedAppointments.slice(offset, offset + appointmentsPerPage);

    return (
        <>
            <h3>Today's Appointments</h3>
            {sortedAppointments.length > 0 ? (
                <>
                    {currentAppointments.map(appointment => {
                        const user = usersData[appointment.email];
                        return (
                            <div key={appointment.email} className="bACard">
                                {user && <img src={`http://localhost:5225/Image/User/${user.img}`} alt="User" />}
                                <div className="appointInfo">
                                    <h1>{appointment.patientName}</h1>
                                    <p>{appointment.from} - {appointment.to}</p>
                                </div>
                                <Link to={`/prescription/${appointment.email}`} className="writeP">Start Session</Link>
                            </div>
                        );
                    })}
                    <div className="pagination">
                        {Array.from({ length: Math.ceil(sortedAppointments.length / appointmentsPerPage) }, (_, index) => (
                            <span
                                key={index}
                                className={`dot ${currentPage === index ? 'active' : ''}`}
                                onClick={() => handlePageClick(index)}
                            ></span>
                        ))}
                    </div>
                </>
            ) : (
                <p className="null">No appointments for today</p>
            )}
            <Link className="showAllAppointments" to={'/AllBookedAppointments'}>View All Patients <img className="viewAllIcon" src={icon2} alt="View All" /></Link>
        </>
    );
};

export default BookedAppointments;
