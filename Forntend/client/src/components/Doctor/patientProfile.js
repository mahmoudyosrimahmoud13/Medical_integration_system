import { useParams } from 'react-router-dom';
import sLS from 'react-secure-storage';
import { useState, useEffect } from "react";

const PatientProfile = () => {
    const { email } = useParams();
    const [user, setUsersData] = useState();
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [sessions, setSession] = useState([]);
    const [drugs, setDrugs] = useState([]);

    const getUserData = async () => {
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
            setUsersData(userData);
        } catch (error) {
            console.error('Error fetching user data:', error);
        }
    };

    const getSession = async () => {
        try {
            const res = await fetch(`http://localhost:5225/Hospital/Doctor/MedicalSession/GetMedicalSessionWithDoctor?PaientEmail=${email}`, {
                method: "GET",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
            });
            if (!res.ok) {
                throw new Error("No user found");
            }
            const userData = await res.json();
            setSession(userData);
        } catch (error) {
            console.error('Error fetching user data:', error);
        }
    };

    const getCurrentDrugs = async () => {
        try {
            const res = await fetch(`http://localhost:5225/Hospital/Patient/information/GetCurrentDrugs?PatientEmail=${email}`, {
                method: "GET",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
            });
            if (!res.ok) {
                throw new Error("No user found");
            }
            const userData = await res.json();
            setDrugs(userData);
        } catch (error) {
            console.error('Error fetching user data:', error);
        }
    };

    useEffect(() => {
        getUserData();
        getSession();
        getCurrentDrugs();
    }, []);

    const toggleDetails = (sessionId) => {
        const details = document.getElementById(`details-${sessionId}`);
        const btn = document.getElementById(`button-${sessionId}`);

        if (details.style.display === "none" || details.style.display === "") {
            details.style.display = "block";
            btn.innerHTML = "Close Details";
        } else {
            details.style.display = "none";
            btn.innerHTML = "View Details";
        }
    };

    return (
        <div className='viewPP'>
            <div className="profile-container">
                <div className="patient-header">
                    {user && <img src={`http://localhost:5225/Image/User/${user.img}`} alt="not found" className="patient-photo" />}
                    <div className="patient-name-container">
                        {user && <h2 className="patient-name">{user.name}</h2>}
                    </div>
                </div>
                <div className="patient-details-container">
                    <div className="detail-boxes">
                        <div className="detail-box">
                            {user && <p>Age: {user.age}</p>}
                        </div>
                        <div className="detail-box">
                            {user && <p>Gender: {user.gender}</p>}
                        </div>
                        <div className="detail-box">
                            {user && <p>Area: {user.area}</p>}
                        </div>
                    </div>
                </div>
                <div className="current-medications">
                    <h3>Current Medications: {drugs.length}</h3>
                    <ul>
                        {drugs.map(drug => (
                            <li key={drug.id}>{drug.name}</li>
                        ))}
                    </ul>
                </div>
                <div className="medical-sessions">
                    <h3>Medical Sessions</h3>
                    {sessions.map(session => (
                        <div className="session" key={session.id}>
                            <h4>Dr. Smith - Cardiologist</h4>
                            <p>Date: 2024-05-01</p>
                            <button
                                onClick={() => toggleDetails(session.id)}
                                id={`button-${session.id}`}
                                className='details-button'
                            >
                                View Details
                            </button>
                            <div id={`details-${session.id}`} className="session-details" style={{ display: 'none' }}>
                                <h5>Diseases Diagnosed</h5>
                                <p>Hypertension, Hyperlipidemia</p>
                                <h5>Doctor's Notes</h5>
                                <p>Patient advised to reduce salt intake and exercise regularly.</p>
                                <h5>Medications Prescribed</h5>
                                <ul>
                                    <li>Medication X - 50mg daily</li>
                                    <li>Medication Y - 20mg daily</li>
                                </ul>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};

export default PatientProfile;
