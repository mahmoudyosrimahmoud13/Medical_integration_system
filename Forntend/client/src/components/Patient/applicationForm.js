import { useState } from "react";
import sLS from 'react-secure-storage';
import image from '../../photos/pngaaa.com-3670877.png';

const PatientForm = ({ doctorId, doctorDates }) => {
    const [from, setValue] = useState('');
    const [day, setValue2] = useState('');
    const [message, setMessage] = useState('');
    const [color, setColor] = useState('red');

    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);

    const data = { from, day };

    
    const extractTimeWithAMPM = (time) => {
        const date = new Date(`2000-01-01T${time}`);
        const formattedTime = date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: true });
        return formattedTime;
    }


    const submit = (e) => {
        e.preventDefault();
        
        const fetchData = async () => {
            try {
                const res = await fetch(`http://localhost:5225/Hospital/Patient/PushDateDoctor?DoctorId=${doctorId}`, {
                    method: "POST",
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
                    if(m === 'Save.'){
                        setMessage("booked successfully !");
                        setColor('#143F6B');
                        setTimeout(() => {
                            cancel();
                        }, 1000);
                    }
                    else if(m === 'Choose The Appropriate Day' || m === 'Choose The Appropriate Time'){
                        setMessage('! this appointment is not available')
                    }
                    else{
                        setMessage('! ' + m);
                    }
                }
            } 
            catch (error) {
            }
        };
        fetchData();
    }
    
    const cancel = () => {
        let af = document.querySelector('.appForm');
        let blur = document.querySelector('.search');

        blur.style.filter = 'blur(0)';
        af.style.display = 'none';
    }
    return(
        <div className="appForm">
        <h2>Doctor Registration Form</h2>
        <img src={image} alt="not found" className="form-image" />
        <form onSubmit={submit}>
            <label htmlFor="date">Date:</label>
            <input type="date" id="appointment-date" name="appointment-time" onChange={(e) => setValue2(e.target.value)} required />
            
            <label htmlFor="appointment-time">Appointment Time:</label>
            <input type="time" id="appointment-time" name="appointment-time" onChange={(e) => setValue(extractTimeWithAMPM(e.target.value))} required />
            <p style={{color: color}} className="msg">{message}</p>
            <div className="button-container">
                <button className="submit">Submit Consultation</button>
                <button className="cancel" onClick={() => cancel()}>Cancel Consultation</button>
            </div>
        </form>
        </div>
    )
}

export default PatientForm;