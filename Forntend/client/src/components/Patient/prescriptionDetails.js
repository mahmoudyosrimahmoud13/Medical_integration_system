import React, { useEffect, useState } from 'react';
import logo from '../../photos/logo1.png';
import sLS from 'react-secure-storage';

const PrescriptionDetails = ({ name, phone, email, disease, date, drug, id }) => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [text, setText] = useState('');
    const [selectedRating, setSelectedRating] = useState(() => {
        return sLS.getItem(`rating-${convertToken.email}`) || null;
    });
    const viewPrescription = document.querySelector('.viewPrescription');
    const closePrescriptionDetails = () => {
        viewPrescription.style.display = 'none';
        setText('');
    };

    const message = 'good';
    const fetchRate = async (rating) => {
        const data = { rate: rating, message };
        try {
            const res = await fetch(`http://localhost:5225/Hospital/Patient/Rate/PushRate?DoctorID=${id}`, {
                method: "POST",
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${convertToken.token}`
                },
                body: JSON.stringify(data)
            });
            if (!res.ok) {
                console.log('bad');
            } else {
                console.log('good');
            }
        } catch (error) {
            console.error(error);
        }
    };

    const rate = (rating) => {
        setSelectedRating(rating);
        sLS.setItem(`rating-${convertToken.email}`, rating);
        fetchRate(rating);
        setText('thanks!');
    };

    useEffect(() => {
        const storedRating = sLS.getItem(`rating-${convertToken.email}`);
        if (storedRating) {
            setSelectedRating(storedRating);
        }
    }, [convertToken.email]);

    return (
        <div className="viewPrescription">
            <img src={logo} alt='not found' />
            <div className="doctor-info">
                <h2>Dr. {name}</h2>
                <p><span className='capital'>phone: </span>{phone}</p>
                <p><span className='capital'>email: </span>{email}</p>
            </div>
            <div className="prescription-details">
                <h3>prescription details</h3>
                <p className='capital'><span>Disease: </span>{disease}</p>
                <p className='capital'><span>Date: </span>{date}</p>
            </div>
            <div className="medications">
                <h3>medications</h3>
                {drug.map((medication, index) => (
                    <div className="medication" key={index}>
                        <p className='capital'><span>drug name: </span> {medication.drugName}</p>
                        <p className='capital'><span>repeat: </span> {medication.repeatCount} daily</p>
                        <p className='capital'><span>instructions: </span> {medication.note}</p>
                        <p className='capital'><span>start date: </span> {medication.startdate}</p>
                        <p className='capital'><span>end date: </span> {medication.enddate}</p>
                    </div>
                ))}
            </div>
            <div className="rateSection">
                <h3>you can rate dr. {name}: </h3>
                <div className="rating">
                    {[5, 4, 3, 2, 1].map((rating) => (
                        <div key={rating}>
                            <input
                                type="radio"
                                id={`heart-${rating}`}
                                name="heart-radio"
                                value={`heart-${rating}`}
                                checked={selectedRating === rating}
                                readOnly
                            />
                            <label htmlFor={`heart-${rating}`}>
                                <svg
                                    onClick={() => rate(rating)}
                                    xmlns="http://www.w3.org/2000/svg"
                                    viewBox="0 0 24 24"
                                    className={selectedRating >= rating ? 'filled' : ''}
                                >
                                    <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"></path>
                                </svg>
                            </label>
                        </div>
                    ))}
                </div>
                <p className='thanks'>{text}</p>
            </div>
            <button onClick={() => closePrescriptionDetails()}>close</button>
        </div>
    );
};

export default PrescriptionDetails;
