import uploadIcon from '../photos/upload.png';
import { useState, useEffect } from 'react';


const Settings = () => {
    const userToken = localStorage.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [user, setData] = useState('');
    const [imgSrc, setSelectedImage] = useState('');
    
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
                // const responseData = await response.json();
                // const updatedConvertToken = { ...convertToken, imgSrc: responseData.imgSrc };
                // localStorage.setItem('usertoken', JSON.stringify(updatedConvertToken)); // Update local storage
                // setConvertToken(updatedConvertToken);
                setSelectedImage(imgSrc);
            }
            else {
                console.error('Error uploading image:', response.statusText);
            }
        } catch (error) {
            console.error('Error uploading image:', error);
        }
    };
    
    
    useEffect(() => {
        getUserData();
        if(imgSrc){
            handleImageUpload();
        }
    }, [url, imgSrc]);

    return(
        <div className="profile">
            <header className="header">
                <div>
                    {imgSrc ? (<img src={URL.createObjectURL(imgSrc)} alt='not found' />) : 
                    (<img src={convertToken.imgSrc} alt='not found' />)}
                    <p>{user.name}</p>
                </div>
            </header>
            <section className="section">
                <div className="form">
                    <h5>general information</h5>
                    <form>
                        <div className='row'>
                            <div className='input'>
                                <label>user name</label>
                                <input type='text' disabled defaultValue={user.name} />
                            </div>
                            <div className='input'>
                                <label>email</label>
                                <input type='email' disabled defaultValue={user.email} />
                            </div>
                        </div>
                        <div className='row'>
                            <div className='input'>
                                <label>gender</label>
                                <select defaultValue={user.gender} disabled >
                                    <option value='true'>Male</option>
                                    <option value='false'>Female</option>
                                </select>
                            </div>
                        </div>
                        <h5>address</h5>
                        <div className='row'>
                            <div className='input'>
                                <label>governorate</label>
                                <input type='text' disabled defaultValue={user.gove} />
                            </div>
                            <div className='input'>
                                <label>area</label>
                                <input type='text' disabled defaultValue={user.area} />
                            </div>
                        </div>
                    </form>

                </div>
                <div className="detailsImg">
                    <h5>Select profile photo</h5>
                    <div className='fileDetails'>
                        <div className='imgPr'>
                            {imgSrc ? (<img src={URL.createObjectURL(imgSrc)} alt='not found' />) : 
                            (<img src={convertToken.imgSrc} alt='not found' />)}
                        </div>
                        <img src={uploadIcon} className='uploadPh' alt='not found' />
                        <input type='file' onChange={handleImageChange} />
                        <div className='type'>
                            <div>Choose Image</div>
                            <div>JPG, GIF or PNG. Max size of 800K</div>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    )
}
export default Settings;
