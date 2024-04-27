import React, { useState, useEffect } from 'react';
import LazyLoad from 'react-lazyload';
import SelectArea from '../components/Patient/selectionArea';
import SelectSpecialtie from '../components/Patient/selectSpecialtie';
import image from '../photos/Doctor-dp-Girl-doctor-removebg-preview.png';
const Home = () => {
    const [doctors, setDoctors] = useState([]);
    const [dates, setDates] = useState([]);


    const [areaID, setAreaID] = useState('');
    const [specialID, setSpecialID] = useState('');


    const userToken = localStorage.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const handleGetSpecialId = (areaId) => {
        setSpecialID(areaId);
    };
    const url = `http://localhost:5225/Hospital/Doctor/GetDoctorsInArea?area=${areaID}&Specialtie=${specialID}&Index=0`;

    const fetchData = async () => {
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
            const data = jsonData.doctors[0].dates;
            // const data2 = jsonData.doctors[0].dates.map((date) => (date.from));
            // const data3 = jsonData.doctors[0].dates.map((date) => (date.to));


            setDates(data);
        } catch (err) {
            console.error(err);
        }
    };
    useEffect(() => {
        if (areaID || specialID) {
            fetchData();
        }
    }, [url]);

    const handleGetAreaId = (areaId) => {
        setAreaID(areaId);
    };
    const show = () => {
        console.log(dates);
    }

    return (
        <div className='home'>
            <SelectArea onGetAreaId={handleGetAreaId} />
            <SelectSpecialtie onGetSpecialId={handleGetSpecialId} />

            <section>
                <div className='cards'>
                    {doctors.map(doctor => (
                        <div className='card' key={doctor.id}>
                            <LazyLoad className='lazy' height={200} once>
                                <img src={image} alt='not found' />
                                <div className='docInf'>
                                    <h1>{doctor.name}</h1>
                                    {dates.map(date => (
                                    <div className='datesInf'>
                                        <p>{date.dayName}</p>
                                        <p>{date.from}</p>
                                        <p>{date.to}</p>
                                    </div>
                                    ))}
                                    {/* {dates && dates.map(dateGroup => (dateGroup.map(date => (<p>{date.dayName}</p>)) ))} */}
                                    <button type='submit'>book now</button>
                                </div>
                            </LazyLoad>
                        </div>
                    ))}
                </div>
            </section>
        </div>
    );
};

export default Home;
