import sLS from 'react-secure-storage';
import { useState, useEffect } from 'react';
import Notifications from './notifications';
import cancelIcon from '../photos/cancelled.png';
import rateIcon from '../photos/rate.png';
import cong from '../photos/congrats.png';
import reg from '../photos/rejected.png';



const ShowAllNotifications = () => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [notifications, setNotifications] = useState([]);

    const getNotifications = async () => {
        try {
            const res = await fetch('http://localhost:5225/api/Notification', {
                method: "GET",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
            });
            const data = await res.json();

            if (res.ok) {
                setNotifications(data);
            } else {
                setNotifications([]);
            }
        } catch (error) {
            console.error('Error fetching notifications:', error);
            setNotifications([]);
        }
    };
    const [check, setCheck] = useState(false);

    const [notif, setNotif] = useState('');
    const [src, setSrc] = useState('');


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
                if(doctorData.message === 'You did it Before'){
                    setNotif('your request to become part of our medical staff. accepted');
                    setSrc(cong);
                    setCheck(true);
                }
            } 
            else if (res.ok) {
                if (doctorData.message === 'Accept') {
                }
                else if (doctorData.error === true) {
                    if (doctorData.message === 'Your Request Has Not Yet been Reviewed') {
                    } 
                    else {
                    }
                }
            }
        } catch (error) {
            throw new Error('no data');
        }
    };

    useEffect(() => {
        getNotifications();
        getDoctorAccept();
    }, []);

    return (
        <div className="notificationsPage">
            <div className="up">
                <Notifications />
            </div>
            <h1>your notifications</h1>
            <div className="down">
                {notifications.length > 0 ? (
                    notifications.map((notification, index) => {
                        if(notification.notifyHeader === 'DoctorCancelYourTime') {
                            return(
                        <div key={index} className="notification">
                            <img className='icon' src={cancelIcon} alt='not found' />
                            <p>{notification.message}.</p>
                        </div>)} 
                        else if(notification.notifyHeader === 'RateDoctor'){
                            return(
                            <div key={index} className="notification">
                            <img className='icon' src={rateIcon} alt='not found' />
                            <p>{notification.message}.</p>
                            </div>)
                        }
                        else{
                            return(
                            <div key={index} className="notification">
                            <p>{notification.message}.</p>
                            </div>)
                        }
                    })
                ) : (
                    null
                )}
                {check ? <div className="notification">
                            <img className='icon' src={src} alt='not found' />
                            <p>{notif}.</p>
                </div> : null}
                
            </div>
        </div>
    );
};

export default ShowAllNotifications;
