import { useState, useEffect } from "react";
import sLS from 'react-secure-storage';

const PatientPrescription = ({diseaseName, date, drugs}) => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [user, setData] = useState('');




    const getDoctorData = async () => {
        try {
            const res = await fetch(`http://localhost:5225/Auth/GetUser?Email=${convertToken.email}`, {
                method: "GET",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
            });
            if (!res.ok) {
                throw new Error("No user found");
            }
            const userData = await res.json();
            setData(userData);
        } catch (error) {
            console.error('Error fetching user data:', error);
        }
    };
    
    
    useEffect(() => {
        getDoctorData();
    }, []);
    return(
        <div className="prescriptionCard">
            {user && <img src={`http://localhost:5225/Image/User/${user.img}`} alt="not found" />}
            <h1>disease name: <span>{diseaseName}</span></h1>
            <div className="currentDrugs">
                <h1>current drugs</h1>  
                <ul>
                    {drugs.map(drug => (
                        <li key={drug.id}>{drug.name}</li>
                    ) )}
                </ul>              
            </div>
            <p>{date}</p>
        </div>
    )
}

export default PatientPrescription;