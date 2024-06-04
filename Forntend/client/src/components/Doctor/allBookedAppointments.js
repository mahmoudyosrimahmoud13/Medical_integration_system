import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import sLS from 'react-secure-storage';
// import icon from '../../photos/right.png';
// import PatientPrescription from "./prescriptionFromDoctor";

const AllBookedAppointments = () => {
    const [appointments, setAppointments] = useState([]);
    // const [email, setEmail] = useState('');

    const [usersData, setUsersData] = useState({});
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);

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
    
    


    useEffect(() => {
        fetchEvents();
    }, []);
    return(
        <>
        <div className="allBookedAppointments">
            <h1>all booked appointments</h1>
            {appointments.map(appointment => {
                const user = usersData[appointment.email];
                return (
                    <>
                    <div key={appointment.email} className="bACard">
                        {user && <img src={`http://localhost:5225/Image/User/${user.img}`} alt="not found" />}
                        <div className="appointInfo">
                            <h1 className="upd">{appointment.patientName}</h1>
                            <p>{appointment.dayName} {appointment.from} - {appointment.to}</p>
                        </div>
                        <Link to={`/profile/${appointment.email}`} className="viewPatient">view</Link>
                    </div>
                    </>
                    )
            })}
        </div>
        </>
    )
}

export default AllBookedAppointments;