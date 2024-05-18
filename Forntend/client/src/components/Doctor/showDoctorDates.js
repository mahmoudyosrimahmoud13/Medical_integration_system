import { useState, useEffect } from "react";
import sLS from 'react-secure-storage';
import editIcon from '../../photos/pen.png';
import delIcon from '../../photos/x-button.png';
import addIcon from '../../photos/plus.png';
import Swal from 'sweetalert2';
import '@mobiscroll/react/dist/css/mobiscroll.min.css';
import { Datepicker, setOptions } from '@mobiscroll/react';


setOptions({
    theme: 'ios',
    themeVariant: 'light'
});
const ShowAllDatesDoctor =  () => {

    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [dates, setDates] = useState([]);
    const [selectedDay, setSelectedDay] = useState(null);
    const [startTime, setStartTime] = useState(null);
    const [endTime, setEndTime] = useState(null);
    const [addDiv, setAddDiv] = useState('');
    const [oldDay, setOldDay] = useState('');

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


    const updateDate = async () => {
        const data = {dayName: getDayName(selectedDay), from: getTimeString(startTime), to: getTimeString(endTime)};
        try {
            const response = await fetch(`http://localhost:5225/Hospital/Doctor/EditAppointmentBook?OldDayName=${oldDay}`, {
                method: "PUT",
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${convertToken.token}`
                },
                body: JSON.stringify(data)
            });
            if (!response.ok) {
                throw new Error('Failed to fetch events');
            }
            fetchEvents();
            hideUPrompt();
        } 
        catch (error) {
            console.error('Error fetching events:', error);
        }
    };


    const deleteDate = async (dayName) => {
        try {
            const response = await fetch(`http://localhost:5225/Hospital/Doctor/DelteAppointmentBook?OldDayName=${dayName}`, {
                method: "DELETE",
                headers: {
                'Authorization': `Bearer ${convertToken.token}`
                },
            });
            if (!response.ok) {
                throw new Error('Failed to fetch events');
            }
            Swal.fire("Deleted!", "Your appointment has been deleted.", "success");
            fetchEvents();
        
        } 
        catch (error) {
            console.error('Error fetching events:', error);
        }
    };

    const fetchEvents = async () => {
        try {
            const response = await fetch('http://localhost:5225/Hospital/Doctor/DoctorDates', {
                method: "GET",
                headers: {
                'Authorization': `Bearer ${convertToken.token}`
                },
            });
            if (!response.ok) {
                throw new Error('Failed to fetch events');
            }
            const data = await response.json();
            setDates(data);
        
        } 
        catch (error) {
            console.error('Error fetching events:', error);
        }
    };
    const deleteBtn = (dayName) => {
        Swal.fire({
            title: "Are you sure?",
            icon: "warning",
            showCancelButton: true,
            confirmButtonText: "Yes, delete it!",
            cancelButtonText: "Cancel",
        }).then((result) => {
            if (result.isConfirmed) {
                deleteDate(dayName);
            } 
        });
    }

    useEffect(() => {
        
        fetchEvents();
    }, []);






    const addDate = async() => {
        const data = {dayName: getDayName(selectedDay), from: getTimeString(startTime), to: getTimeString(endTime)};
        const da = [data];
        if(!selectedDay || !startTime || !endTime ){
            return setAddDiv('Please add your Appointments');
        }
        const res = await fetch(`http://localhost:5225/Hospital/Doctor/AddAppointmentBook`,{
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${convertToken.token}`
            },
            body: JSON.stringify(da)
        })
        const msg = await res.text();

        if(!res.ok) {
            setAddDiv(msg);
        }
        if(res.ok){
            hidePrompt();
            fetchEvents();
        }
    }
    const prompt = document.querySelector('.dates');
    const updatePrompt = document.querySelector('.updateDates');


    const showPrompt = () => {
        prompt.style.display = 'block';

    }
    const hidePrompt = () => {
        prompt.style.display = 'none';
    }
    const showUPrompt = () => {
        updatePrompt.style.display = 'block';

    }
    const hideUPrompt = () => {
        updatePrompt.style.display = 'none';
    }
    return(
        <>
        <div className='showDocDates'>
            <h3>your dates</h3>
            <div className="allDates">
                {dates.map(date => (
                    <div key={date.dayName} className="datesCards">
                        <p>{date.dayName} {date.from} - {date.to}</p>
                        <div className="iconsDatesDoctor">
                        <img className="doctoeDateImage" src={editIcon} alt="not found" onClick={() => {setOldDay(date.dayName); showUPrompt()}} />
                        <img className="doctoeDateImage" src={delIcon} alt="not found" onClick={() => deleteBtn(date.dayName)} />
                        </div>
                    </div>
                ))}
                <img className="addBtnIcon" src={addIcon} alt="not found" onClick={() => showPrompt()} />
            </div>
            
        </div>
        <div className="dates">
        <Datepicker
            controls={['calendar', 'time']}
            select="range"
            label="Calendar & Time"
            labelStyle="stacked"
            inputStyle="outline"
            placeholder="Please Add your Dates..."
            onChange={handleDateTimeChange}
            />
        {addDiv && <p className="addDiv">! {addDiv}</p>}
        <div className="promptBtns">
        <button className="addPromptBtn" onClick={() => addDate()}>
            <span className="circle1"></span>
            <span className="circle2"></span>
            <span className="circle3"></span>
            <span className="circle4"></span>
            <span className="circle5"></span>
            <span className="text">Add</span>
        </button>
        <button className="cancelPrompt" onClick={() => hidePrompt()}>
            <span className="circle1"></span>
            <span className="circle2"></span>
            <span className="circle3"></span>
            <span className="circle4"></span>
            <span className="circle5"></span>
            <span className="text">Cancel</span>
        </button>
        </div>
        </div>
        <div className="updateDates">
        <Datepicker
            controls={['calendar', 'time']}
            select="range"
            label="Calendar & Time"
            labelStyle="stacked"
            inputStyle="outline"
            placeholder="Update your Dates..."
            onChange={handleDateTimeChange}
            />
        {/* {addDiv && <p className="addDiv">! {addDiv}</p>} */}
        <div className="promptBtns">
        <button className="addPromptBtn" onClick={() => updateDate()}>
            <span className="circle1"></span>
            <span className="circle2"></span>
            <span className="circle3"></span>
            <span className="circle4"></span>
            <span className="circle5"></span>
            <span className="text">Update</span>
        </button>
        <button className="cancelPrompt" onClick={() => hideUPrompt()}>
            <span className="circle1"></span>
            <span className="circle2"></span>
            <span className="circle3"></span>
            <span className="circle4"></span>
            <span className="circle5"></span>
            <span className="text">Cancel</span>
        </button>
        </div>
        </div>
        </>
    )
}
export default ShowAllDatesDoctor;