import icon from '../../photos/group.png';
import icon2 from '../../photos/stethoscope.png';
import { useEffect } from 'react';
// import sLS from 'react-secure-storage';


const Reports = ({ getNumberPatients, patients }) => {
    // const userToken = sLS.getItem('usertoken');
    // const convertToken = JSON.parse(userToken);
    // const [patients, setPatients] = useState('');






    // const urlAppointments = `http://localhost:5225/Hospital/Doctor/BookedAppointments`;



    
    
    // const getNumberPatients = async () => {
    //     try {
    //             const res = await fetch(urlAppointments, {
    //                 method: "GET",
    //                 headers: {
    //                     'Authorization': `Bearer ${convertToken.token}`
    //                 },
    //             });
    //             if (!res.ok) {
    //                 throw new Error("no appointments");
    //             }
    //             const data = await res.json();
    //             setPatients(data.length);
    //             if(data.length < 1){
    //                 setPatients('0');
    //             }
    //         }
    //         catch (error) {
    //             throw new Error('no data');  
    //         }
    // };


    useEffect(() => {
        getNumberPatients();
    }, [getNumberPatients]);
    return(
        <>
            <h3>reports</h3>
            <div className='numbers'>
                <div className='number'>
                    <div>
                        <img src={icon} alt='not found' />
                        <p>patients</p>
                    </div>
                    {patients && <h1>{patients}</h1>}
                </div>
                <div className='number'>
                    <div>
                        <img src={icon2} alt='not found' />
                        <p>consultation</p>
                    </div>
                    {patients && <h1>{patients}</h1>}
                </div>
            </div>
        </>
    )
}
export default Reports;