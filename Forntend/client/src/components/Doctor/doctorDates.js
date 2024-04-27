import '@mobiscroll/react/dist/css/mobiscroll.min.css';
import { Datepicker, Page, setOptions } from '@mobiscroll/react';
import { useState } from 'react';
setOptions({
    theme: 'ios',
    themeVariant: 'light'
});



const Dates = () => {
    const [selectedDay, setSelectedDay] = useState(null);
    const [startTime, setStartTime] = useState(null);
    const [endTime, setEndTime] = useState(null);
    const [addDiv, setAddDiv] = useState('');
    const userToken = localStorage.getItem('usertoken');
    const convertToken = JSON.parse(userToken);



    const handleDateTimeChange = (event, inst) => {
        const selectedValues = inst.getVal();
        if (selectedValues && selectedValues.length > 0) {
            setSelectedDay(selectedValues[0]); 
            setStartTime(selectedValues[0]);
            setEndTime(selectedValues[1]);
        } else {
            setSelectedDay(null);
            setStartTime(null);
            setEndTime(null);
        }
    };


    const getDayName = (date) => {
        const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        if(selectedDay){
            return days[date.getDay()];
        }
    };


    const getTimeString = (time) => {
        if (!time) return '';
        return time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    };




    const addDate = async() => {
        const data = {dayName: getDayName(selectedDay), from: getTimeString(startTime), to: getTimeString(endTime)};
        if(!selectedDay || !startTime || !endTime ){
            return setAddDiv('Please add values');
        }
        const res = await fetch(`http://localhost:5225/Hospital/Doctor/AddAppointmentBook`,{
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${convertToken.token}`
            },
            body: JSON.stringify(data)
        })
        if(!res.ok) {
            setAddDiv('the date is already added');
        }
        if(res.ok){
            setAddDiv('Added Successfully');
        }
    }

    return(
        <>
        <Page className='contDP'>
                <Datepicker className='dateP'
                controls={['calendar', 'time']}
                select="range"
                label="Calendar & Time"
                labelStyle="stacked"
                inputStyle="outline"
                placeholder="Please Add your Dates..."
                onChange={handleDateTimeChange}
                />
            {addDiv && <p>{addDiv}</p>}
            <button onClick={() => addDate()}>
                <span class="circle1"></span>
                <span class="circle2"></span>
                <span class="circle3"></span>
                <span class="circle4"></span>
                <span class="circle5"></span>
                <span class="text">Add</span>
            </button>
        </Page>
        </>
    )
}
export default Dates;