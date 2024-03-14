import FetchHook from '../../components/login/fetchHook';
import ClinicAreasProps from '../../components/Doctor/clinicAreasProps';
import SpecialtiesProps from '../../components/Doctor/specialtiesProps';
import image from '../../photos/Health_professional_team_Customizable_Isometric_Illustrations___Amico_Style-removebg-preview.png';
import { useState } from 'react';
import SuccessfullyMsg from '../../components/success';
import LazyLoad from 'react-lazyload';



const BeDoctor = () => {
    const [areaClinicId, setValue] = useState('');
    const [addressDescrption, setValue2] = useState('');
    const [collegeName, setValue3] = useState('');
    const [graduationYear, setValue4] = useState('');
    const [specialtieId, setValue5] = useState('');
    const [summaryCareer, setValue6] = useState('');
    const [certificates, setValue7] = useState('');

    
    const [errorMsg, setErrorMsg] = useState(null);
    // const navigate = useNavigate();

    // let form = document.querySelector('.form');

    let notif = document.getElementById('notif');
    let notifText = document.getElementById('notifText');
    let prog = document.getElementById('prog');


    const userToken = localStorage.getItem('usertoken');
    const convertToken = JSON.parse(userToken);

    const specialties = FetchHook(`http://localhost:5225/Hospital/Specialties`);
    const areas = FetchHook(`http://localhost:5225/Adress/GetAreas?GovermentKey=${convertToken.gove}`);

    
    
    const apply = (e) => {
        e.preventDefault();
        

        const formData = new FormData();
        const input = {
            areaClinicId: areaClinicId,
            addressDescrption: addressDescrption,
            collegeName: collegeName,
            graduationYear: graduationYear ,
            specialtieId: specialtieId,
            SummaryCareer: summaryCareer,
        };
        formData.append("input", JSON.stringify(input));
        formData.append("Certificates", certificates);
        const fetchData = async () => {
            try {
                    const res = await fetch('http://localhost:5225/Hospital/Doctor/AddDoctor', {
                        method: "POST",
                        headers: {
                            'Authorization': `Bearer ${convertToken.token}`
                        },
                        body: formData
                    });
                    const doctorToken = await res.json();
                    if (!res.ok) {
                        setErrorMsg('* Must fill inputs');
                        throw new Error(doctorToken.message);
                    }
                    else if(res.ok){
                        if(doctorToken.error === true){
                            setErrorMsg("*"+doctorToken.message);
                        }
                        else{
                            notifText.innerHTML = doctorToken.message;
                            notif.style.animation= 'fade-in 3s linear';
                            prog.style.animation = 'progress 2.5s 0.3s linear';
                        }
                        
                    }
                }
                catch (error) {
                    console.log(error.message);
                }
            };
            fetchData();
    }


    return(
        <div className="bedoc">
            <div className="form">
                <LazyLoad className='img' height={200} once>
                        <img src={image} alt="" />
                </LazyLoad>
                <div className='forminfo'>
                    <h1>sir, you can join our team now.</h1>
                    <form onSubmit={apply}>
                    <label className='cat'>address</label>
                        <div className='formrow'>
                            <div className='forminput'>
                                <label>clinic area</label>
                                {areas && 
                                <select defaultValue="" onChange={(e) => setValue(e.target.value)}>
                                    <option value="" disabled>Select Your Area</option>
                                    <ClinicAreasProps areas={areas} />
                                </select>}
                            </div>
                            <div className='forminput'>
                                <label>address descrption</label>
                                <input type='text' onChange={(e) => setValue2(e.target.value)} />
                            </div>
                        </div>
                        <label className='cat'>information</label>
                        <div className='formrow'>
                            <div className='forminput'>
                                <label>college name</label>
                                <input type='text' onChange={(e) => setValue3(e.target.value)} />
                            </div>
                            <div className='forminput'>
                                <label>graduation year</label>
                                <input type='date' onChange={(e) => setValue4(e.target.value)} />
                            </div>
                        </div>
                        <div className='formrow'>
                            <div className='forminput'>
                                <label>specialization</label>
                                {specialties && 
                                <select defaultValue="" onChange={(e) => setValue5(e.target.value)} >
                                        <option value="" disabled>Select Your Specialization</option>
                                        <SpecialtiesProps specialties={specialties} />
                                </select>}
                            </div>
                            <div className='forminput'>
                                <label>career summary</label>
                                <textarea onChange={(e) => setValue6(e.target.value)} />
                            </div>
                        </div>
                        <div className='formrow'>
                            <div className='forminput'>
                                <label>upload certificates</label>
                                    <input className='file' type='file' multiple onChange={(e) => setValue7([...e.target.files])} />
                            </div>
                        </div>
                        <p style={{color: 'red', marginTop: '10px'}}>{errorMsg}</p>
                        <button className='apply'><span>apply</span></button>
                    </form>
                </div>
            </div>
            <SuccessfullyMsg />
        </div>
    )
}
export default BeDoctor;