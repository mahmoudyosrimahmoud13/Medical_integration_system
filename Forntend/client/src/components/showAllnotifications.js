import Notifications from "./notifications";
import sLS from 'react-secure-storage';
import { useState, useEffect } from 'react';
import icon from '../photos/congrats.png';
    

const ShowAllNotifications = () => {
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
                    if(doctorData.message === 'Accept'){
                        const updatedToken = { ...convertToken, token: doctorData.token };
                        sLS.setItem('usertoken', JSON.stringify(updatedToken));
                        setNotifications(true);
                    }
                    setNotifications(false);

                }
            }
            catch (error) {
                throw new Error('no data');  
            }
    };

    useEffect(() => {
        getDoctorAccept();
    }, []);
    return(
        <div className="notificationsPage">
            <div className="up">
                <Notifications />
            </div>
            <div className="down">
                {notifications ? 
                <>
                <div><img className="cong" src={icon} alt="not found" /><p>your request to become part of our medical staff. accepted</p></div>
                </> : <p>! there are no notifications</p>}
            </div>
        </div>
    )
}
export default ShowAllNotifications;