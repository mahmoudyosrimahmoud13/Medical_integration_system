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
                if(!res.ok) {
                    setNotifications(false);
                }
                else if(res.ok){
                    // if(doctorData.message === 'Accept'){
                        // const updatedToken = { ...convertToken, token: doctorData.token };
                        // sLS.setItem('usertoken', JSON.stringify(updatedToken));
                        setNotifications(true);
                    // }
                    if(doctorData.error === true){
                        setNotifications(false);
                    }
                }
            }
            catch (error) {
                throw new Error('no data');  
            }
    };

    useEffect(() => {
        getDoctorAccept();
        setInterval(getDoctorAccept, 3 * 60 * 10000);
    }, []);

    const handleClickNotifications = () => {
        setNotifications(false);
    };

    return(
        <div className="header">
            <div className='images'>
                <Link to={'/notifications'} className={notifications ? 'notifications' : ''} onClick={handleClickNotifications}>
                    <img className='notifIcon' src={notifIcon} alt='not found' />
                </Link>
                <img className='profileIcon' src={convertToken.imgSrc} alt='not found' />
            </div>
        </div>
    )
}

export default Notifications;