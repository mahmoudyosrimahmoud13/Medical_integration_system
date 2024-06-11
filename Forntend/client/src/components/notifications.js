import notifIcon from '../photos/bell.png';
import sLS from 'react-secure-storage';
import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';

const Notifications = () => {
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
                const now = new Date();
                const recentNotifications = data.filter(notification => {
                    const notificationTime = new Date(notification.timestamp);
                    return (now - notificationTime) <= 3 * 60 * 1000; // Check if within last 3 minutes
                });
                setNotifications(recentNotifications);
            } else {
                setNotifications([]);
            }
        } catch (error) {
            console.error('Error fetching notifications:', error);
            setNotifications([]);
        }
    };

    useEffect(() => {
        getNotifications();
        const interval = setInterval(getNotifications, 3 * 60 * 1000); // 3 minutes in milliseconds
        return () => clearInterval(interval); // Clean up interval on component unmount
    }, []);

    return (
        <div className="header">
            <div className='images'>
                <Link to='/notifications' className={notifications.length + 1 ? 'notifications' : null}>
                    <img className='notifIcon' src={notifIcon} alt='not found' />
                </Link>
                <img className='profileIcon' src={convertToken.imgSrc} alt='not found' />
            </div>
        </div>
    );
};

export default Notifications;
