import { useState } from "react";
import sLS from 'react-secure-storage';

const PatientForm = ({ doctorId }) => {
    const [from, setValue] = useState('');
    const [day, setValue2] = useState('');
    const [message, setMessage] = useState('');
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
                        setMessage("booked successfully");
                        setTimeout(() => {
                            cancel();
                        }, 2000);
                    }
                    else if(m === 'Choose The Appropriate Day' || m === 'Choose The Appropriate Time'){
                        setMessage('! that appointment is not available')
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
        let af = document.querySelector('.af');
        af.style.display = 'none'
        // let cs = document.querySelector('.cards');

        // af.style.opacity = 0;
        // af.style.zIndex = '1';
        // cs.style.zIndex = '2';
        // cs.style.filter = "blur(0)";
    }

    return(
        <form className="af" onSubmit={submit}>
            <h1>consultation form</h1>
            <div className="row">
                <div className="inputP">
                    <label>day</label>
                    <input type="date" onChange={(e) => setValue2(e.target.value)} required />
                </div>
                <div className="inputP">
                    <label>time</label>
                    <input type="time" onChange={(e) => setValue(extractTimeWithAMPM(e.target.value))} required />
                </div>
            </div>
            <div className="row">
                <p className="msg">{message}</p>
            </div>
            <div className="row">
            <button>submit consultation</button>
            <button onClick={() => cancel()}>close form</button>
            </div>
        </form>
    )
}

export default PatientForm;