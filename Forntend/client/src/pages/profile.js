import uploadIcon from '../photos/upload.png';
import { useState, useEffect } from 'react';
import sLS from 'react-secure-storage';
import PatientAppointments from '../components/Patient/appointments';
import { useNavigate } from 'react-router-dom';
import Notifications from '../components/notifications';


const Settings = () => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const navigate = useNavigate();

    const [user, setData] = useState('');
    const [imgSrc, setSelectedImage] = useState('');
    // const [role, setRole] = useState('');

    const url = `http://localhost:5225/Auth/GetUser?Email=${convertToken.email}`;
    const getUserData = async () => {
        try {
                const res = await fetch(url, {
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


    const handleImageChange = (event) => {
        setSelectedImage(event.target.files[0]);
    };


    const handleImageUpload = async () => {
        try {
            const formData = new FormData();
            formData.append('img', imgSrc);
            // const imageUrlWithCacheBuster = `${convertToken.imgSrc}?cacheBuster=${Date.now()}`;
            const response = await fetch('http://localhost:5225/Auth/ChangePhoto', {
                method: 'PUT',
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
                body: formData
            });
            
            if(response.ok) {
                setSelectedImage(imgSrc);
            }
            else {
                console.error('Error uploading image:', response.statusText);
            }
        } catch (error) {
            console.error('Error uploading image:', error);
        }
    };
    
    // const getDoctorAccept = async () => {
    //     try {
    //             const res = await fetch('http://localhost:5225/Hospital/Doctor/CheackRoleDoctor', {
    //                 method: "GET",
    //                 headers: {
    //                     'Authorization': `Bearer ${convertToken.token}`
    //                 },
    //             });
    //             const doctorData = await res.json();
    //             if(!res.ok) {
    //                 if(doctorData.error === true){
    //                     setRole('doctor');
    //                 }
    //             }
    //             else if(res.ok){
    //                 if(doctorData.message === 'Accept'){
    //                     const updatedToken = { ...convertToken, token: doctorData.token };
    //                     sLS.setItem('usertoken', JSON.stringify(updatedToken));
    //                     setRole('doctor');
    //                 }
    //                 else if(doctorData.error === true){
    //                     setRole('patient');
    //                 }
    //             }
    //         }
    //         catch (error) {
    //             throw new Error('no data');  
    //         }
    // };
    const logout = () => {
        sLS.removeItem('usertoken');
        navigate('/login');
    };
    useEffect(() => {
        getUserData();
        // getDoctorAccept();
        if(imgSrc){
            handleImageUpload();
        }
    }, [url, imgSrc]);
    return(
        <div className="profile">
            <Notifications />
            <section className="section">
                <div className="form">
                <div className="detailsImg">
                    <div className='fileDetails'>
                        <div className='imgPr'>
                            {imgSrc ? (<img src={URL.createObjectURL(imgSrc)} alt='not found' />) : 
                            (<img src={convertToken.imgSrc} alt='not found' />)}
                        </div>
                        <img src={uploadIcon} className='uploadPh' alt='not found' />
                        <input type='file' onChange={handleImageChange} />
                        <div className='type'>
                            <div className='h5'>Choose Image</div>
                            <div>JPG, GIF or PNG. Max size of 800KB</div>
                        </div>
                    </div>
                </div>
                <div className='generalInformation'></div>
                    <div className='rowGeneralInformation'>
                        <h5>general information</h5>
                        <div className='information'>
                            <p><span>name: </span>{user.name}</p>
                            <p><span>email: </span>{user.email}</p>
                            <p><span>gender: </span>{user.gender}</p>                        
                        </div>
                    </div>
                    <div className='rowGeneralInformation'>
                        <h5>address</h5>
                        <div className='information'>
                            <p><span>city: </span>{user.gove}</p>
                            <p><span>area: </span>{user.area}</p>
                        </div>
                    </div>
                    
                    <div className='rowGeneralInformation'>
                        {/* <h5>role: <span className='role'>{role}</span></h5> */}
                        <div className='information'>
                        <button className="Btn" onClick={logout}>
                        <div className="sign"><svg viewBox="0 0 512 512"><path d="M377.9 105.9L500.7 228.7c7.2 7.2 11.3 17.1 11.3 27.3s-4.1 20.1-11.3 27.3L377.9 406.1c-6.4 6.4-15 9.9-24 9.9c-18.7 0-33.9-15.2-33.9-33.9l0-62.1-128 0c-17.7 0-32-14.3-32-32l0-64c0-17.7 14.3-32 32-32l128 0 0-62.1c0-18.7 15.2-33.9 33.9-33.9c9 0 17.6 3.6 24 9.9zM160 96L96 96c-17.7 0-32 14.3-32 32l0 256c0 17.7 14.3 32 32 32l64 0c17.7 0 32 14.3 32 32s-14.3 32-32 32l-64 0c-53 0-96-43-96-96L0 128C0 75 43 32 96 32l64 0c17.7 0 32 14.3 32 32s-14.3 32-32 32z"></path></svg></div>
                        <div className="text">Logout</div>
                    </button>
                        </div>
                        
                    </div>
                    
                </div>
                <div className='rightPatientProfile'>
                    <PatientAppointments />
                </div>
            </section>
        </div>
    )
}
export default Settings;
