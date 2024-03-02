// import image from '../photos/Dexter.jpg';
import uploadIcon from '../photos/upload.png';
import { useState, useEffect } from 'react';
const Profile = () => {
    const userToken = localStorage.getItem('usertoken');
    const [convertToken, setConvertToken] = useState(JSON.parse(userToken));


    const [imgSrc, setSelectedImage] = useState('');


    const handleImageChange = (event) => {
        setSelectedImage(event.target.files[0]);
    };
    const handleImageUpload = async () => {
        try {
            const formData = new FormData();
            formData.append('img', imgSrc);
            const response = await fetch('http://localhost:5225/Auth/ChangePhoto', {
                method: 'PUT',
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
                body: formData
            });
            
            if (response.ok) {
                const responseData = await response.json();
                const updatedConvertToken = { ...convertToken, imgSrc: responseData.imgSrc };
                setConvertToken(updatedConvertToken);
                console.log('Image uploaded successfully:', responseData);
            }
            else {
                console.error('Error uploading image:', response.statusText);
            }
        } catch (error) {
            console.error('Error uploading image:', error);
        }
    };
    
    
    
    useEffect(() => {
        if(imgSrc){
            handleImageUpload();
        }
    }, [imgSrc]);

    return(
        <div className="profile">
            <header className="header">
                <div>
                    {imgSrc ? (<img src={URL.createObjectURL(imgSrc)} alt='not found' />) : 
                    (<img src={convertToken.imgSrc} alt='not found' />)}
                    <p>{convertToken.email}</p>
                </div>
            </header>
            <section className="section">
                <div className="form">
                    <h5>general information</h5>
                    <form>
                        <div className='row'>
                            <div className='input'>
                                <label>user name</label>
                                <input type='text' defaultValue={convertToken.userName} />
                            </div>
                            <div className='input'>
                                <label>email</label>
                                <input type='email' defaultValue={convertToken.email} />
                            </div>
                        </div>
                        <div className='row'>
                            <div className='input'>
                                <label>gender</label>
                                <select defaultValue={convertToken.gender} >
                                    <option value='true'>Male</option>
                                    <option value='false'>Female</option>
                                </select>
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
                        <input type='file' accept="image/*" onChange={handleImageChange} />
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
export default Profile;
