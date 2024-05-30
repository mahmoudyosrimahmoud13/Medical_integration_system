import React, { useState, useEffect } from 'react';
import LazyLoad from 'react-lazyload';
import SelectArea from '../components/Patient/selectionArea';
import SelectSpecialtie from '../components/Patient/selectSpecialtie';
import imageMale from '../photos/istockphoto-1494673298-612x612-removebg-preview.png';
import imageFemale from '../photos/Doctor-dp-Girl-doctor-removebg-preview.png';

import PatientForm from '../components/Patient/applicationForm';

import sLS from 'react-secure-storage';


const Search = () => {
    const [doctors, setDoctors] = useState([]);

    const [selectedDoctorId, setSelectedDoctorId] = useState('0');
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [areaID, setAreaID] = useState('');
    const [specialID, setSpecialID] = useState('');
    // const [rate, setRate] = useState(1);

    
    const handleGetSpecialId = (speciaId) => {
        setSpecialID(speciaId);
    };
    // let url;
    
    // if(areaID && specialID){
    //     url = `http://localhost:5225/Hospital/Doctor/GetDoctorsInArea?area=${areaID}&Specialtie=${specialID}&Index=0`;
    // }
    // else if(specialID){
    //     url = `http://localhost:5225/Hospital/Doctor/GetDoctorsInArea?Specialtie=${specialID}&Index=0`;
    // }

    const fetchData = async (url) => {
        try {
            const res = await fetch(url, {
                method: "GET",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                }
            });
            if (!res.ok) {
                throw Error("Error");
            }
            const jsonData = await res.json();
            setDoctors(jsonData.doctors);
        } catch (err) {
            console.error(err);
        }
    };
    

    useEffect(() => {
        let url;
        if (specialID && areaID) {
            url = `http://localhost:5225/Hospital/Doctor/GetDoctorsInArea?area=${areaID}&Specialtie=${specialID}&Index=0`;
        } else if (specialID) {
            url = `http://localhost:5225/Hospital/Doctor/GetDoctorsInArea?Specialtie=${specialID}&Index=0`;
        }
        if (url) {
            fetchData(url);
        }
    }, [specialID, areaID]);

    const handleGetAreaId = (areaId) => {
        setAreaID(areaId);
    };
    
    const showForm = (doctorId) => {
        setSelectedDoctorId(doctorId);

        let af = document.querySelector('.af');
        af.style.display = 'flex';
    }
    // const message = 'good';
    // const fetchRate = async (rating) => {
    //     const data = { rate: rating, message };
    //     try {
    //         const res = await fetch(`http://localhost:5225/Hospital/Patient/Rate/PushRate?DoctorID=9e721d6d-6e23-4329-86cf-cac01acb9185`, {
    //             method: "POST",
    //             headers: {
    //                 'Content-Type': 'application/json',
    //                 'Authorization': `Bearer ${convertToken.token}`
    //             },
    //             body: JSON.stringify(data)
    //         });
    //         if (!res.ok) {
    //             console.log('bad');
    //         } else {
    //             console.log('good');
    //         }
    //     } catch (error) {
    //         console.error(error);
    //     }
    // };
    


    return (
        <div className='home'>
            <div className='searchS'>
                <SelectArea onGetAreaId={handleGetAreaId} />
                <SelectSpecialtie onGetSpecialId={handleGetSpecialId} />
            </div>
            
            <section>
                <div className='cards'>
                    {doctors.map(doctor => (
                        <div className='card' key={doctor.id}>
                            <LazyLoad className='lazy' height={200} once>
                                {doctor.gender === true? (<img src={imageMale} alt='not found' />)
                                : (<img src={imageFemale} alt='not found' />)}
                                {/* <div className="rating">
                                    <input type="radio" id="star-1" name="star-radio" value="star-1" />
                                    <label htmlFor="star-1">
                                        <svg onClick={() => fetchRate(4)} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path pathLength="360" d="M12,17.27L18.18,21L16.54,13.97L22,9.24L14.81,8.62L12,2L9.19,8.62L2,9.24L7.45,13.97L5.82,21L12,17.27Z"></path></svg>
                                    </label>
                                    <input type="radio" id="star-2" name="star-radio" value="star-1" />
                                    <label htmlFor="star-2">
                                        <svg onClick={() => fetchRate(3)} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path pathLength="360" d="M12,17.27L18.18,21L16.54,13.97L22,9.24L14.81,8.62L12,2L9.19,8.62L2,9.24L7.45,13.97L5.82,21L12,17.27Z"></path></svg>
                                    </label>
                                    <input type="radio" id="star-3" name="star-radio" value="star-1" />
                                    <label htmlFor="star-3">
                                        <svg onClick={() => fetchRate(2)} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path pathLength="360" d="M12,17.27L18.18,21L16.54,13.97L22,9.24L14.81,8.62L12,2L9.19,8.62L2,9.24L7.45,13.97L5.82,21L12,17.27Z"></path></svg>
                                    </label>
                                    <input type="radio" id="star-4" name="star-radio" value="star-1" />
                                    <label htmlFor="star-4">
                                        <svg onClick={() => fetchRate(1)} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path pathLength="360" d="M12,17.27L18.18,21L16.54,13.97L22,9.24L14.81,8.62L12,2L9.19,8.62L2,9.24L7.45,13.97L5.82,21L12,17.27Z"></path></svg>
                                    </label>
                                </div> */}
                                <div className='docInf'>
                                    <h1>dr. {doctor.name}</h1>
                                    {doctor.dates && doctor.dates.map((date, index) => (
                                    <div key={index} className='datesInf'>
                                        <p>{date.dayName}</p>
                                        <p>{date.from}</p>
                                        <p>{date.to}</p>
                                    </div>
                                    ))}
                                    <button type='submit' onClick={() => showForm(doctor.id)}>book now</button>
                                </div>
                            </LazyLoad>
                        </div>
                    ))}
                </div>
            </section>
            {selectedDoctorId && <PatientForm doctorId={selectedDoctorId} />}
        </div>
    );
};

export default Search;
