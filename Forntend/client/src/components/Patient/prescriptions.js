import { useState, useEffect } from "react";
import sLS from 'react-secure-storage';
import PrescriptionDetails from "./prescriptionDetails";

const Prescriptions = () => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [prescriptions, setPrescriptions] = useState([]);
    const [docId, setDocID] = useState('');
    const [docName, setDocName] = useState('');
    const [docPhone, setDocPhone] = useState('');
    const [docEmail, setDocEmail] = useState('');
    const [diseaseName, setDiseaseName] = useState('');
    const [date, setDate] = useState('');
    const [drugDetails, setDetails] = useState([]);



    const fetchPrescriptions = async () => {
        try {
            const response = await fetch(`http://localhost:5225/Hospital/Patient/Information/Repentances`, {
                method: "GET",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
            });
            if (!response.ok) {
                throw new Error('Failed to fetch events');
            }
            const data = await response.json();
            setPrescriptions(data);
            setDocID(data.doctorId);
            } catch (error) {
                console.error('Error fetching events:', error);
            }
    };
    
    const viewPrescription = document.querySelector('.viewPrescription');
    const showPrescriptionDetails = (name, phone, email, disease, date, drug, id) => {
        setDocName(name);
        setDocPhone(phone);
        setDocEmail(email);
        setDiseaseName(disease);
        setDate(date);
        setDetails(drug);
        setDocID(id);
        viewPrescription.style.display = 'block';
    }

    useEffect(() => {
        fetchPrescriptions();
    }, []);
    return(
        <>
        <div className="allPrescriptionsProfile">
            <h1 className="head">All your sessions</h1>
            {prescriptions.map(prescription => (
                <div key={prescription.doctorId} className="prescription">
                <img src={`http://localhost:5225/Image/User/${prescription.doctorImg}`} alt="not found" />
                <div className="appointInfo">
                    <h1>dr. {prescription.dcotorName}</h1>
                </div>
                <p>{prescription.date}</p>
                <button onClick={() => showPrescriptionDetails(prescription.dcotorName, prescription.doctorPhone, prescription.doctorEmail, prescription.diseaseName, prescription.date, prescription.repentances, prescription.doctorId)}>view session</button>
            </div>
            ))}
        </div>
        <PrescriptionDetails name={docName} phone={docPhone} email={docEmail} disease={diseaseName} date={date} drug={drugDetails} id={docId} />
        </>
    )
}

export default Prescriptions;