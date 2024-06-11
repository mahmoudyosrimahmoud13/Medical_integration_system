import { useState, useEffect } from "react";
import sLS from 'react-secure-storage';


const AcceptDoctors = () => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [applicants, setApplicants] = useState([]);

    const fetchEvents = async () => {
        try {
            const response = await fetch('http://localhost:5225/Hospital/Doctor/GetDoctorsNotActive?index=0', {
                method: "GET",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
            });
            if (!response.ok) {
                throw new Error('Failed to fetch events');
            }
            const data = await response.json();
            setApplicants(data.doctors);
        } catch (error) {
            console.error('Error fetching events:', error);
        }
    };
    const doc_Accept_Reject = async (docId, value) => {
        try {
            const response = await fetch(`http://localhost:5225/Hospital/Doctor/ActionDoctor?Id=${docId}&&action=${value}`, {
                method: "PUT",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
            });
            if (!response.ok) {
                throw new Error('Failed to fetch events');
            }
            fetchEvents();
        } catch (error) {
            console.error('Error fetching events:', error);
        }
    };



    useEffect(() => {
        fetchEvents();
    }, []);
    return(
        <div className="acceptDoctors">
        <h1>all applicants</h1>
        {applicants.length > 0 ? (applicants.map(applicant => (
            <div className="acceptDoctor" key={applicant.id}>
                <img src={applicant.drImg} alt="not found" />
                <div className="name-email">
                    <p className="capital"><span>name: </span> {applicant.name}</p>
                    <p><span>email: </span> {applicant.email}</p>
                </div>
                <p><span>phone: </span> {applicant.phone}</p>
                <div className="name-email">
                    <p className="capital">{applicant.collegeName} faculty department of {applicant.departmentName}</p>
                    <p>{new Date(applicant.graduationYear).toLocaleDateString()}</p>
                </div>
                <div className="btnsAR">
                <button onClick={() => doc_Accept_Reject(applicant.id, true)}>accept</button>
                <button onClick={() => doc_Accept_Reject(applicant.id, false)}>reject</button>
                </div>
            </div>
        ))) : <p style={{color: '#143F6B', textTransform: 'capitalize', fontSize: '1.2rem', fontWeight: 400}}>there ar no applicants !</p>}
        </div>
    )
}

export default AcceptDoctors;