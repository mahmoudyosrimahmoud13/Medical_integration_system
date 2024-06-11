import { useState, useEffect } from "react";
import sLS from 'react-secure-storage';
import editIcon from '../../photos/pen.png';
import delIcon from '../../photos/x-button.png';
import addIcon from '../../photos/plus.png';
import Swal from 'sweetalert2';


const ShowAllDatesDoctor =  () => {

    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [dates, setDates] = useState([]);
    const [selectedDay, setSelectedDay] = useState(null);
    const [startTime, setStartTime] = useState(null);
    const [endTime, setEndTime] = useState(null);
    const [addDiv, setAddDiv] = useState('');
    const [addDiv2, setAddDiv2] = useState('');

    const [oldDay, setOldDay] = useState('');

    

    const getDayName = (date) => {
        const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        if (date) {
            const dayIndex = new Date(date).getDay();
            return days[dayIndex];
        }
        return '';
    };

    const getTimeString = (time) => {
        const [hour, minute] = time.split(':');
        let period = 'AM';
        let hour12 = parseInt(hour, 10);

        if (hour12 >= 12) {
            period = 'PM';
            if (hour12 > 12) hour12 -= 12;
        }
        if (hour12 === 0) hour12 = 12;

        return `${hour12.toString().padStart(2, '0')}:${minute} ${period}`;
    };
    const updateDate = async () => {
        const data = { dayName: getDayName(selectedDay), from: getTimeString(startTime), to: getTimeString(endTime) };
        if (!selectedDay || !startTime || !endTime) {
            return setAddDiv2('Please add your Appointments');
        }
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
        } catch (error) {
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
        } catch (error) {
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
        } catch (error) {
            console.error('Error fetching events:', error);
        }
    };

    const deleteBtn = (dayName) => {
        Swal.fire({
            title: "Are you sure you want cancel this appointment?",
            icon: "warning",
            showCancelButton: true,
            confirmButtonText: "Yes, cancel it!",
            cancelButtonText: "No",
        }).then((result) => {
            if (result.isConfirmed) {
                deleteDate(dayName);
            }
        });
    }

    useEffect(() => {
        fetchEvents();
    }, []);

    const addDate = async () => {

        const data = { dayName: getDayName(selectedDay), from: getTimeString(startTime), to: getTimeString(endTime) };
        const da = [data];
        const res = await fetch(`http://localhost:5225/Hospital/Doctor/AddAppointmentBook`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${convertToken.token}`
            },
            body: JSON.stringify(da)
        })
        const msg = await res.text();

        if (!res.ok) {
            setAddDiv(msg);
        }

        if (res.ok) {
            if(!selectedDay && !startTime && !endTime){
                setAddDiv('fields required');
            }
            else if(msg === 'Chaeck Dates'){
                setAddDiv('You have an appointment that day');
            }
            else{
                hidePrompt();
                fetchEvents();
            }
        }
    }

    const prompt = document.querySelector('.dates');
    const updatePrompt = document.querySelector('.updateDates');

    const showPrompt = () => {
        prompt.style.display = 'flex';
    }

    const hidePrompt = () => {
        prompt.style.display = 'none';
    }

    const showUPrompt = () => {
        updatePrompt.style.display = 'flex';
    }

    const hideUPrompt = () => {
        updatePrompt.style.display = 'none';
    }

    return(
        <>
        <div className='showDocDates'>
            <h3>your dates</h3>
            <div className="allDates">
                
                {dates.length > 0 ? (dates.map(date => (
                    <div key={date.dayName} className="datesCards">
                        <p>{date.dayName} {date.from} - {date.to}</p>
                        <div className="iconsDatesDoctor">
                        <img className="doctoeDateImage" src={editIcon} alt="not found" onClick={() => {setOldDay(date.dayName); showUPrompt()}} />
                        <img className="doctoeDateImage" src={delIcon} alt="not found" onClick={() => deleteBtn(date.dayName)} />
                        </div>
                    </div>
                ))) : <p className="null">! you don't add any dates</p>}
                <img className="addBtnIcon" src={addIcon} alt="not found" onClick={() => showPrompt()} />
            </div>
            
        </div>
        <div className="dates">
            <p className="lbl">add new appointment</p>
            <div className="add_date">
                <label htmlFor="date">Day:</label>
                <input type="date" id="date" name="date" required onChange={(e) => setSelectedDay(e.target.value)} />
            </div>
            <div className="form-group-time">
            <div className="add_date">
                <label htmlFor="from-time">From:</label>
                <input type="time" id="from-time" name="from-time" required onChange={(e) => setStartTime(e.target.value)} />
            </div>
            <div className="add_date">
                <label htmlFor="to-time">To:</label>
                <input type="time" id="to-time" name="to-time" required onChange={(e) => setEndTime(e.target.value)} />
            </div>
        </div>
            
        
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
        <p className="lbl">update old appointment</p>
        <div className="add_date">
                <label htmlFor="date">Day:</label>
                <input type="date" id="date" name="date" required onChange={(e) => setSelectedDay(e.target.value)} />
            </div>
            <div className="form-group-time">
            <div className="add_date">
                <label htmlFor="from-time">From:</label>
                <input type="time" id="from-time" name="from-time" required onChange={(e) => setStartTime(e.target.value)} />
            </div>
            <div className="add_date">
                <label htmlFor="to-time">To:</label>
                <input type="time" id="to-time" name="to-time" required onChange={(e) => setEndTime(e.target.value)} />
            </div>
        </div>
        {addDiv2 && <p className="addDiv">! {addDiv2}</p>}
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