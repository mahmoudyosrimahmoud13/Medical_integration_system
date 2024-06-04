import notifIcon from '../photos/bell.png';
import sLS from 'react-secure-storage';
import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';

const Notifications = () => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [notifications, setNotifications] = useState(false);

    const getDoctorAccept = async () => {
        try {
            const res = await fetch('http://localhost:5225/Hospital/Doctor/CheackRoleDoctor', {
                method: "GET",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
            });
            const doctorData = await res.json();

            if (!res.ok) {
                setNotifications(false);
            } 
            else if (res.ok) {
                if (doctorData.message === 'Accept') {
                    setNotifications(true);
                }
                else if (doctorData.error === true) {
                    if (doctorData.message === 'Your Request Has Not Yet been Reviewed') {
                        setNotifications(false);
                    } 
                    else {
                        sLS.setItem('notif', true);
                        setNotifications(true);
                    }
                }
            }
        } catch (error) {
            throw new Error('no data');
        }
    };
    setInterval(getDoctorAccept, 3 * 60 * 10000);
    const check = sLS.getItem('error');
    const err = JSON.parse(check);
    
    useEffect(() => {
        getDoctorAccept();
        if(err === false){
            setNotifications(false);
        }
        else if(err === true){
            setNotifications(true);
        }
        
        // return () => clearInterval(interval);
    }, []);
    
    const handleClickNotifications = () => {
        // sLS.setItem('notif', false);
        setNotifications(false);
    };

    return (
        <div className="header">
            <div className='images'>
                <Link to='/notifications' onClick={handleClickNotifications} className={notifications ? 'notifications' : ''}>
                    <img className='notifIcon' src={notifIcon} alt='not found' />
                </Link>
                <img className='profileIcon' src={convertToken.imgSrc} alt='not found' />
            </div>
        </div>
    );
};

export default Notifications;
