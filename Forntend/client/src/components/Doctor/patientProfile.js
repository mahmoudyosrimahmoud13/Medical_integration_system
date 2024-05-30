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
    return(
        <div className='viewPatientProfile'>
            <div className='profileCard'>
                {user && <img src={`http://localhost:5225/Image/User/${user.img}`} alt="not found" />}
                {user && <h1 className='name'>{user.name}</h1>}
                <h1 className='label'>all sessions:</h1>
                {sessions.map(session => (
                    <div key={session.id} className='sessions'>
                        <p><span>disease name: </span>{session.diseaseName}</p>
                        <p><span>date: </span>{session.sessionDate}</p>
                    </div>
                ))}
                <h1 className='label'>current drugs: </h1>
                <ul>
                    {drugs.map(drug => (
                        <li key={drug.id}>{drug.name}</li>
                    ))}
                </ul>
            </div>
        </div>
    )
}

export default PatientProfile;