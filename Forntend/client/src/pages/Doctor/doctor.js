import doctorImage from '../../photos/istockphoto-1494673298-612x612-removebg-preview.png';
import femaleImage from '../../photos/Doctor-dp-Girl-doctor-removebg-preview.png';
import { useState, useEffect } from 'react';
import Charts from '../../components/Doctor/charts';
import Calendar from '../../components/Doctor/calendar';
import Navbar from '../../components/Doctor/navbar';
import Reports from '../../components/Doctor/roports';
import sLS from 'react-secure-storage';
import BookedAppointments from '../../components/Doctor/bookedAppointments';
import ShowAllDatesDoctor from '../../components/Doctor/showDoctorDates';
import Notifications from '../../components/notifications';

const Doctor = () => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [user, setData] = useState('');
    const [specialites, setSpecialites] = useState('');
    const urlUser = `http://localhost:5225/Auth/GetUser?Email=${convertToken.email}`;
    


    const urlSpecialites = `http://localhost:5225/Hospital/Doctor/GetDoctorSpecialtie`;

    const getDoctorDB = async () => {
        try {
                const res = await fetch(urlSpecialites, {
                    method: "GET",
                    headers: {
                        'Authorization': `Bearer ${convertToken.token}`
                    },
                });
                if (!res.ok) {
                    throw new Error("no appointments");
                }
                
                const data = await res.text();

                setSpecialites(data);
                
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
        getDoctorDB();
    }, [urlSpecialites, urlUser]);


    return(
        <>
        <div className="doctor">
            <Navbar />
            <div className="page">
                <Notifications />
                <div className="content">
                    <div className='center'>
                        <div className='doctorInfo'>
                            <div className='doctorData'>
                                <p>Welcome back,</p>
                                <h1>dr. {user.name}</h1>
                                <p>{specialites}</p>
                                <p>check your <span>appointments</span> today!</p>
                            </div>
                            {convertToken.gender ? <img src={doctorImage} alt='not found' /> : 
                            <img src={femaleImage} alt='not found' />}
                        </div>
                        <div className='middle'>
                        <div className='middleL'>
                            <div className='reports'>
                                <Reports />
                            </div>
                            <div className='charts'>
                                <Charts />
                            </div>
                        </div>
                        <div className='middleR'>
                            <ShowAllDatesDoctor />
                        </div>
                        </div>
                        
                    </div>
                    <div className='right'>
                        <div className='appointments'>
                            <p>your appointments</p>
                            <div className='calendar'>
                            <Calendar />
                            </div>
                        </div>
                        <div className='booked'>
                            <BookedAppointments />
                        </div>
                    </div>
                </div>
            </div>
        </div>
        </>
    )
}
export default Doctor