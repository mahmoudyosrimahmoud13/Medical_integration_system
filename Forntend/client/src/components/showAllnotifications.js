import Notifications from "./notifications";
import sLS from 'react-secure-storage';
import { useState, useEffect } from 'react';
import icon from '../photos/congrats.png';
import icon2 from '../photos/rejected.png';

const ShowAllNotifications = () => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [notifications, setNotifications] = useState(false);
    const [opacity, setOpacity] = useState(1);
    const [text, setText] = useState('');
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
                sLS.setItem('error', true);
                
                if(!res.ok) {
                    if(doctorData.message === 'You did it Before'){
                        setNotifications(true);
                        setOpacity(.5);
                        setText('your request to become part of our medical staff. accepted')
                        setSrc(icon);
                    }
                    else{
                        setNotifications(false);
                    }
                }
                else if(res.ok){
                    if(doctorData.message === 'Accept'){
                        setNotifications(true);
                        const updatedToken = { ...convertToken, token: doctorData.token };
                        sLS.setItem('usertoken', JSON.stringify(updatedToken));
                        setText('your request to become part of our medical staff. accepted');
                        setSrc(icon);
                    }
                    else if(doctorData.error === true){
                        if(doctorData.message === 'Your Request Has Not Yet been Reviewed'){
                            setNotifications(false);
                        }
                        else{
                            setText(doctorData.message);
                            setNotifications(true);
                            setSrc(icon2);
                            sLS.setItem('error', false);
                        }
                    }
                    // setNotifications(false);
                }
            }
            catch (error) {
                throw new Error('no data');  
            }
    };
    
    useEffect(() => {
        getDoctorAccept();
        const check = sLS.getItem('error');
        const err = JSON.parse(check);
        if(err === false){
            setOpacity(.5);
        }
    }, []);
    return(
        <div className="notificationsPage">
            <div className="up">
                <Notifications />
            </div>
            <div className="down">
                {notifications ?
                <>
                <div style={{ opacity: opacity }} className="notification"><img className="cong" src={src} alt="not found" /><p>{text}</p></div>
                </> : <p>! there are no notifications</p>}
            </div>
        </div>
    )
}
export default ShowAllNotifications;