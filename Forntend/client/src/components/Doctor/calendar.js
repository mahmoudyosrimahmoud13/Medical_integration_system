import '@mobiscroll/react/dist/css/mobiscroll.min.css';
import { Eventcalendar, Popup, setOptions } from '@mobiscroll/react';
import { useCallback, useMemo, useEffect, useRef, useState } from 'react';
import sLS from 'react-secure-storage';
import Prescription from '../../pages/Doctor/prescriptionForm';

setOptions({
  theme: 'ios',
  themeVariant: 'light'
});

const Calendar = () => {
  const userToken = sLS.getItem('usertoken');
  const convertToken = JSON.parse(userToken);
  const [appointments, setAppointments] = useState([]);
  
  useEffect(() => {
    const fetchEvents = async () => {
      try {
        const response = await fetch('http://localhost:5225/Hospital/Doctor/BookedAppointments', {
          method: "GET",
          headers: {
            'Authorization': `Bearer ${convertToken.token}`
          },
        });
        if (!response.ok) {
          throw new Error('Failed to fetch events');
        }
        const data = await response.json();
      setAppointments(data);
        
      } catch (error) {
        console.error('Error fetching events:', error);
      }
    };

    fetchEvents();
  }, []);

  const [isOpen, setOpen] = useState(false);
  const [anchor, setAnchor] = useState(null);
  const [currentEvent, setCurrentEvent] = useState(null);

  const [time, setTime] = useState('');
  const [endTime, setEndTime] = useState('');
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');

  const timerRef = useRef(null);

  const myView = useMemo(() => ({ calendar: { type: 'week' } }), []);

  const handleEventHoverIn = useCallback((args) => {
    const event = args.event;
    setCurrentEvent(event);
    setTime(event.from);
    setEndTime(event.to);
    setName(event.patientName);
    setPhone(event.patientPhone);
    setEmail(event.email);

    if (timerRef.current) {
      clearTimeout(timerRef.current);
    }

    setAnchor(args.domEvent.target);
    setOpen(true);
  }, []);

  const handleEventHoverOut = useCallback(() => {
    timerRef.current = setTimeout(() => {
      setOpen(false);
    }, 200);
  }, []);

  const handleEventClick = useCallback(() => {
    setOpen(true);
  }, []);

  const handleMouseEnter = useCallback(() => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
    }
  }, []);

  const handleMouseLeave = useCallback(() => {
    timerRef.current = setTimeout(() => {
      setOpen(false);
    }, 200);
  }, []);

  const prescriptionOpen = () => {
    const prescriptionForm = document.querySelector('.prescriptionForm');
    const center = document.querySelector('.center');
    const calendarAppointments = document.querySelector('.calendarAppointments');
    const datesSection = document.querySelector('.dates');

    prescriptionForm.style.opacity = 1;
    center.style.zIndex = '0';
    calendarAppointments.style.zIndex = '0';
    datesSection.style.zIndex = '0';
  };

  return (
    <>
      <Eventcalendar
        className='calendarAppointments'
        view={myView}
        data={appointments}
        clickToCreate={false}
        dragToCreate={false}
        dragToMove={true}
        dragToResize={false}
        showEventTooltip={false}
        height={200}
        onEventHoverIn={handleEventHoverIn}
        onEventHoverOut={handleEventHoverOut}
        onEventClick={handleEventClick}
      />
      <Popup
        display="anchored"
        isOpen={isOpen}
        anchor={anchor}
        touchUi={false}
        showOverlay={false}
        contentPadding={false}
        closeOnOverlayClick={false}
        width={350}
        cssClass="md-tooltip"
      >
        <div className='pop' onMouseEnter={handleMouseEnter} onMouseLeave={handleMouseLeave}>
          <div className="md-tooltip-header" style={{ backgroundColor: '#87CEEB' }}>
            <span className="md-tooltip-name-age">{name}, </span>
            <span className="md-tooltip-time">{time} : </span>
            <span className="md-tooltip-time">{endTime}</span>
          </div>
          <div className="md-tooltip-info">
            <div className="md-tooltip-title">
              Email: <span className="md-tooltip-status md-tooltip-text">{email}</span>
            </div>
            <div className="md-tooltip-title">
              Phone: <span className="md-tooltip-status md-tooltip-text">{phone}</span>
            </div>
            {/* <button className="writeP" onClick={prescriptionOpen}>write the prescription</button> */}
          </div>
        </div>
      </Popup>
      {/* <Prescription patientEmail={email} name={name} /> */}
    </>
  );
}

export default Calendar;
