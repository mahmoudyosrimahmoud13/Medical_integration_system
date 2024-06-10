import React, { useState, useEffect } from 'react';
import LazyLoad from 'react-lazyload';
import SelectArea from '../components/Patient/selectionArea';
import SelectSpecialtie from '../components/Patient/selectSpecialtie';

import PatientForm from '../components/Patient/applicationForm';

import sLS from 'react-secure-storage';


const Search = () => {
    const [doctors, setDoctors] = useState([]);

    const [selectedDoctorId, setSelectedDoctorId] = useState('0');
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [areaID, setAreaID] = useState('');
    const [specialID, setSpecialID] = useState('');
    const [doctorDates, setDates] = useState([]);

    
    const handleGetSpecialId = (speciaId) => {
        setSpecialID(speciaId);
    };
    

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
            setDates(jsonData.doctors);
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
        let af = document.querySelector('.appForm');
        let blur = document.querySelector('.search');

        af.style.display = 'flex';
        blur.style.filter = 'blur(5px)';
    }
    
    
    


    return (
        <div className='home'>
            <h1>serach for doctors</h1>
            <div className='searchS'>
                <SelectArea onGetAreaId={handleGetAreaId} />
                <SelectSpecialtie onGetSpecialId={handleGetSpecialId} />
            </div>
            <section className='search'>
                <div className='cards'>
                    {doctors.map(doctor => (
                        <div className='card' key={doctor.id}>
                            <LazyLoad className='lazy' height={200} once>
                                <img src={doctor.drImg} alt='not found' />
                                <div className='docInf'>
                                    <h1>dr. {doctor.name}</h1>
                                    {doctor.dates && doctor.dates.map((date, index) => (
                                    <div key={index} className='datesInf'>
                                        <p>{date.dayName}</p>
                                        <p>{date.from}</p>
                                        <p>{date.to}</p>
                                    </div>
                                    ))}
                                    <button type='submit' onClick={() => {showForm(doctor.id); setSelectedDoctorId(doctor.id)}}>book now</button>
                                </div>
                            </LazyLoad>
                        </div>
                    ))}
                </div>
            </section>
            {selectedDoctorId && <PatientForm doctorId={selectedDoctorId} dates={doctorDates} />}
        </div>
    );
};

export default Search;
