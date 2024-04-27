import icon from '../../photos/group.png';
import icon2 from '../../photos/stethoscope.png';
import icon3 from '../../photos/heart.png';
import { useState, useEffect } from 'react';


const Reports = () => {
    const userToken = localStorage.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [patients, setPatients] = useState('');
    const [appointments, setAppointments] = useState('');


    const url = `http://localhost:5225/Hospital/Doctor/CountOfPatientsWithDoctor`;




    const urlAppointments = `http://localhost:5225/Hospital/Doctor/BookedAppointments`;



    const getNumberAppointments = async () => {
        try {
                const res = await fetch(urlAppointments, {
                    method: "GET",
                    headers: {
                        'Authorization': `Bearer ${convertToken.token}`
                    },
                });
                if (!res.ok) {
                    throw new Error("no appointments");
                }
                const data = await res.json();
                setAppointments(data);
                if(data.length < 1){
                    setAppointments('0');
                }
            }
            catch (error) {
                throw new Error('no data');  
            }
    };
    
    const getNumberPatients = async () => {
        try {
                const res = await fetch(url, {
                    method: "GET",
                    headers: {
                        'Authorization': `Bearer ${convertToken.token}`
                    },
                });
                if (!res.ok) {
                    throw new Error("no appointments");
                }
                const data = await res.json();
                setPatients(data);
                if(data.length < 1){
                    setPatients('0');
                }
            }
            catch (error) {
                throw new Error('no data');  
            }
    };


    useEffect(() => {
        getNumberPatients();
        getNumberAppointments();
    }, [url, urlAppointments]);
    return(
        <>
            <h3>reports</h3>
            <div className='numbers'>
                <div className='number'>
                    <div>
                        <img src={icon} alt='not found' />
                        <p>patients</p>
                    </div>
                    {patients && <h1>{patients}</h1>}
                </div>
                <div className='number'>
                    <div>
                        <img src={icon2} alt='not found' />
                        <p>consultation</p>
                    </div>
                    {appointments && <h1>{appointments}</h1>}
                </div>
                <div className='number'>
                    <div>
                        <img src={icon3} alt='not found' />
                        <p>love</p>
                    </div>
                    <h1>100</h1>
                </div>
            </div>
        </>
    )
}
export default Reports;