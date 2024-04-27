import doctorImage from '../../photos/istockphoto-1494673298-612x612-removebg-preview.png';
import femaleImage from '../../photos/Doctor-dp-Girl-doctor-removebg-preview.png';
import notifIcon from '../../photos/bell.png';
import { useState, useEffect } from 'react';
import Charts from '../../components/Doctor/charts';
import Calendar from '../../components/Doctor/calendar';
import Navbar from '../../components/Doctor/navbar';
import Reports from '../../components/Doctor/roports';
import Dates from '../../components/Doctor/doctorDates';



const Doctor = () => {
    
    const userToken = localStorage.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [user, setData] = useState('');
    const [appointments, setAppointments] = useState('0');
    const [specialites, setSpecialites] = useState('');


    
    const urlUser = `http://localhost:5225/Auth/GetUser?Email=${convertToken.email}`;
    

    const urlAppointments = `http://localhost:5225/Hospital/Doctor/BookedAppointments`;

    const urlDoctor = `http://localhost:5225/Hospital/Doctor/GetDoctor?Id=9e721d6d-6e23-4329-86cf-cac01acb9185`;

    const getDoctorDB = async () => {
        try {
                const res = await fetch(urlDoctor, {
                    method: "GET",
                    headers: {
                        'Authorization': `Bearer ${convertToken.token}`
                    },
                });
                if (!res.ok) {
                    throw new Error("no appointments");
                }
                const data = await res.json();
                setSpecialites(data);
                if(data.length < 1){
                    setAppointments('0');
                }
            }
            catch (error) {
                throw new Error('no data');  
            }
    };

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


    const getUserData = async () => {
        try {
                const res = await fetch(urlUser, {
                    method: "GET",
                    headers: {
                        'Authorization': `Bearer ${convertToken.token}`
                    },
                });
                if (!res.ok) {
                    throw new Error("no user");
                }
                const userData = await res.json();
                setData(userData);
            }
            catch (error) {
                throw new Error('no data');  
            }
    };
    useEffect(() => {
        getUserData();
        getNumberAppointments();
        getDoctorDB();
    }, [urlUser, urlAppointments, urlDoctor]);


    return(
        <div className="doctor">
            <Navbar />
            <div className="page">
                <div className="header">
                    <h1>dashboard</h1>
                    <div className='images'>
                        <div className="search">
                            <svg className="searchIcon" aria-hidden="true" viewBox="0 0 24 24"><g><path d="M21.53 20.47l-3.66-3.66C19.195 15.24 20 13.214 20 11c0-4.97-4.03-9-9-9s-9 4.03-9 9 4.03 9 9 9c2.215 0 4.24-.804 5.808-2.13l3.66 3.66c.147.146.34.22.53.22s.385-.073.53-.22c.295-.293.295-.767.002-1.06zM3.5 11c0-4.135 3.365-7.5 7.5-7.5s7.5 3.365 7.5 7.5-3.365 7.5-7.5 7.5-7.5-3.365-7.5-7.5z"></path></g></svg>
                            <input placeholder="Search" type="search" className="searchInput" />
                        </div>
                        <img className='notifIcon' src={notifIcon} alt='not found' />
                        <img className='profileIcon' src={convertToken.imgSrc} alt='not found' />
                    </div>
                </div>
                <div className="content">
                    <div className='center'>
                        <div className='doctorInfo'>
                            <div className='doctorData'>
                                <p>Welcome back,</p>
                                <h1>dr. {user.name}</h1>
                                {specialites && <p>{specialites.departmentName}</p>}
                                <p>you have total {appointments && <span>{appointments} appointments</span>} today!</p>
                            </div>
                            {convertToken.gender ? <img src={doctorImage} alt='not found' /> : 
                            <img src={femaleImage} alt='not found' />}
                        </div>
                        <div className='reports'>
                            <Reports />
                        </div>
                        <div className='charts'>
                            <Charts />
                        </div>
                    </div>
                    <div className='right'>
                        <div className='appointments'>
                            <p>your appointments</p>
                            <div className='calendar'>
                            <Calendar />
                            </div>
                        </div>
                        <div className='dates'>
                            <Dates />
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}
export default Doctor