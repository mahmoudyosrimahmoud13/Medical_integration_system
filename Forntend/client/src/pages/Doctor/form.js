// import { useState } from 'react';
import FetchHook from '../../components/login/fetchHook';
import ClinicAreasProps from '../../components/Doctor/clinicAreasProps';
import SpecialtiesProps from '../../components/Doctor/specialtiesProps';
import image from '../../photos/Health_professional_team_Customizable_Isometric_Illustrations___Amico_Style-removebg-preview.png';



const BeDoctor = () => {
    const areas = FetchHook(`http://localhost:5225/Adress/GetAreas`);
    const specialties = FetchHook(`http://localhost:5225/Adress/GetSpecialties`);
    // const [clinicarea, setValue] = useState('');
    // const [address, setValue2] = useState('');
    // const [collegeName, setValue3] = useState('');
    // const [graduationYear, setValue4] = useState('');
    // const [specialization, setValue5] = useState('');
    // const [career summary, setValue6] = useState('');



    return(
        <div className="bedoc">
            <div className="form">
                <div className='img'>
                    <img src={image} alt="" />
                </div>
                <div className='forminfo'>
                    <h1>sir, you can join our team now.</h1>
                    <form>
                    <label className='cat'>address</label>
                        <div className='formrow'>
                            <div className='forminput'>
                                <label>clinic area</label>
                                {areas && 
                                <select >
                                    <ClinicAreasProps areas={areas} />
                                </select>}
                            </div>
                            <div className='forminput'>
                                <label>address descrption</label>
                                <input type='text' />
                            </div>
                        </div>
                        <label className='cat'>information</label>
                        <div className='formrow'>
                            <div className='forminput'>
                                <label>college name</label>
                                <input type='text' />
                            </div>
                            <div className='forminput'>
                                <label>graduation year</label>
                                <input type='number' />
                            </div>
                        </div>
                        <div className='formrow'>
                            <div className='forminput'>
                                <label>specialization</label>
                                {specialties && 
                                <select >
                                    <SpecialtiesProps specialties={specialties} />
                                </select>}
                            </div>
                            <div className='forminput'>
                                <label>career summary</label>
                                <textarea />
                            </div>
                        </div>
                        <button className='apply'>apply</button>
                    </form>
                </div>
            </div>
        </div>
    )
}
export default BeDoctor;