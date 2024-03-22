// import '@mobiscroll/react/dist/css/mobiscroll.min.css';
// import { Eventcalendar, momentTimezone, setOptions } from '@mobiscroll/react';
// import moment from 'moment-timezone';
// import { useMemo, useEffect, useState } from 'react';

// momentTimezone.moment = moment;

// setOptions({
//     theme: 'ios',
//     themeVariant: 'light'
// });

// const Calendar = () => {
//     const [events, setEvents] = useState([]);

//     useEffect(() => {
//         const fetchEvents = async () => {
//             try {
//                 const response = await fetch('https://api-generator.retool.com/ePa8Iy/appointments');
//                 if (!response.ok) {
//                     throw new Error('Failed to fetch events');
//                 }
//                 const data = await response.json();
//                 setEvents(data);
//             } catch (error) {
//                 console.error('Error fetching events:', error);
//             }
//         };

//         fetchEvents();
//     }, []);

//     const myEvents = useMemo(() => {
//         return events.map(event => ({
//             start: event.date,
//             // end: event.end,
//             title: event.name,
//             color: event.color,
//         }));
//     }, [events]);

// const myView = useMemo(() => ({ calendar: { popover: true, type: 'month' } }), []);

//     return (
//         <div className='calendar'>
//             <Eventcalendar
//                 clickToCreate={false}
//                 dragToCreate={false}
//                 dragToMove={false}
//                 dragToResize={false}
//                 eventDelete={false}
//                 dataTimezone="utc"
//                 displayTimezone="local"
//                 timezonePlugin={momentTimezone}
//                 data={myEvents}
//                 view={myView}
//         />
//         </div>
//     );
// }

// export default Calendar;

import '@mobiscroll/react/dist/css/mobiscroll.min.css';
import { Button, Eventcalendar, formatDate, Popup, setOptions, Toast } from '@mobiscroll/react';
import { useCallback, useMemo, useEffect, useRef, useState } from 'react';

setOptions({
  theme: 'ios',
  themeVariant: 'light'
});

const defaultAppointments = [
  {
    title: 'Jude Chester',
    age: 69,
    start: '2024-03-10T08:00',
    end: '2024-03-10T09:00',
    confirmed: false,
    reason: 'Headaches morning & afternoon',
    location: 'Topmed, Building A, Room 203',
    color: '#143F6B',
  },
  {
    title: 'Leon Porter',
    age: 44,
    start: '2024-03-10T09:00',
    end: '2024-03-10T10:00',
    confirmed: false,
    reason: 'Left abdominal pain',
    location: 'Topmed, Building D, Room 360',
    color: '#143F6B',
  },
  {
    title: 'Lily Racquel',
    age: 54,
    start: '2024-03-10T10:00',
    end: '2024-03-10T11:00',
    confirmed: true,
    reason: 'Dry, persistent cough & headache',
    location: 'Procare, Building C, Room 12',
    color: '#143F6B',
  },
  {
    title: 'Mia Sawyer',
    age: 59,
    start: '2024-03-10T11:00',
    end: '2024-03-10T12:00',
    confirmed: true,
    reason: 'Difficulty sleeping & loss of appetite',
    location: 'Procare, Building C, Room 12',
    color: '#143F6B',
  },
  {
    title: 'Jon Candace',
    age: 63,
    start: '2024-03-10T12:00',
    end: '2024-03-10T13:00',
    confirmed: true,
    reason: 'Nausea & weakness',
    location: 'MedStar, Building A, Room 1',
    color: '#143F6B',
  },
  {
    title: 'Layton Drake',
    age: 57,
    start: '2024-03-10T13:00',
    end: '2024-03-10T14:00',
    confirmed: true,
    reason: 'Headaches & loss of appetite',
    location: 'Vitalife, Room 160',
    color: '#143F6B',
  },
  {
    title: 'Willis Kane',
    age: 44,
    start: '2024-03-11T08:00',
    end: '2024-03-11T09:00',
    confirmed: true,
    reason: 'Back pain',
    location: 'Care Cente, Room 320r',
    color: '#143F6B',
  },
  {
    title: 'Theo Calanthia',
    age: 60,
    start: '2024-03-11T09:00',
    end: '2024-03-11T10:00',
    confirmed: true,
    reason: 'Anxiousness & sleeping disorder',
    location: 'Care Center, Room 320',
    color: '#143F6B',
  },
  {
    title: 'Ford Kaiden',
    age: 53,
    start: '2024-03-11T14:00',
    end: '2024-03-11T15:00',
    confirmed: true,
    reason: 'Nausea & vomiting',
    location: 'Care Center, Room 206',
    color: '#143F6B',
  },
  {
    title: 'Gerry Irma',
    age: 50,
    start: '2024-03-11T13:00',
    end: '2024-03-11T14:00',
    confirmed: false,
    reason: 'Fever & sore throat',
    location: 'Medica Zone, Building C, Room 2',
    color: '#143F6B',
  },
  {
    title: 'Carlyn Dorothy',
    age: 36,
    start: '2024-03-11T14:00',
    end: '2024-03-11T15:00',
    confirmed: true,
    reason: 'Tiredness & muscle pain',
    location: 'Medica Zone, Building C, Room 2',
    color: '#143F6B',
  },
  {
    title: 'Alma Potter',
    age: 74,
    start: '2024-03-09T10:00',
    end: '2024-03-09T11:00',
    confirmed: true,
    reason: 'High blood pressure',
    location: 'Vitacure, Building D, Room 2',
    color: '#143F6B',
  },
  {
    title: 'Debra Aguilar',
    age: 47,
    start: '2024-03-09T11:00',
    end: '2024-03-09T12:00',
    confirmed: false,
    reason: 'Fever & sore throat',
    location: 'Vitacure, Building D, Room 2',
    color: '#143F6B',
  },
  {
    title: 'Marjorie White',
    age: 55,
    start: '2024-03-09T13:00',
    end: '2024-03-09T14:00',
    confirmed: true,
    reason: 'Back pain',
    location: 'Vitacure, Building D, Room 2',
    color: '#143F6B',
  },
  {
    title: 'Lora Wilson',
    age: 66,
    start: '2024-03-09T15:00',
    end: '2024-03-09T16:00',
    confirmed: false,
    reason: 'Fever & headache',
    location: 'Vitacure, Building D, Room 2',
    color: '#143F6B',
  },
  {
    title: 'Christie Baker',
    age: 71,
    start: '2024-03-09T10:00',
    end: '2024-03-09T11:00',
    confirmed: true,
    reason: 'Headaches morning & afternoon',
    location: 'Care Center, Room 300',
    color: '#143F6B',
  },
  {
    title: 'Arlene Lyons',
    age: 41,
    start: '2024-03-09T14:00',
    end: '2024-03-09T15:00',
    confirmed: true,
    reason: 'Nausea & weakness',
    location: 'Care Center, Room 202',
    color: '#143F6B',
  },
  {
    title: 'Dory Edie',
    age: 45,
    start: '2024-03-08T09:00',
    end: '2024-03-08T10:00',
    confirmed: true,
    reason: 'Right abdominal pain',
    location: 'Vitacure, Building A, Room 203',
    color: '#143F6B',
  },
  {
    title: 'Kaylin Toni',
    age: 68,
    start: '2024-03-08T10:00',
    end: '2024-03-08T11:00',
    confirmed: true,
    reason: 'Itchy, red rashes',
    location: 'Vitacure, Building A, Room 203',
    color: '#143F6B',
  },
  {
    title: 'Gray Kestrel',
    age: 60,
    start: '2024-03-08T12:00',
    end: '2024-03-08T13:00',
    confirmed: true,
    reason: 'Cough & fever',
    location: 'Vitacure, Building A, Room 203',
    color: '#143F6B',
  },
  {
    title: 'Lou Andie',
    age: 76,
    start: '2024-03-08T15:00',
    end: '2024-03-08T16:00',
    confirmed: true,
    reason: 'High blood pressure',
    location: 'Medica Zone, Room 13',
    color: '#143F6B',
  },
  {
    title: 'Yancy Dustin',
    age: 52,
    start: '2024-03-08T10:00',
    end: '2024-03-08T11:00',
    confirmed: true,
    reason: 'Fever & headache',
    location: 'Vitacure, Building E, Room 50',
    color: '#143F6B',
  },
  {
    title: 'Terry Clark',
    age: 78,
    start: '2024-03-08T11:00',
    end: '2024-03-08T12:00',
    confirmed: true,
    reason: 'Swollen ankles',
    location: 'Vitacure, Building E, Room 50',
    color: '#143F6B',
  },
];


    

const Calendar = () => {
//   const [events, setEvents] = useState([]);

//     useEffect(() => {
//         const fetchEvents = async () => {
//             try {
//                 const response = await fetch('https://api-generator.retool.com/ePa8Iy/appointments');
//                 if (!response.ok) {
//                     throw new Error('Failed to fetch events');
//                 }
//                 const data = await response.json();
//                 setEvents(data);
//             } catch (error) {
//                 console.error('Error fetching events:', error);
//             }
//         };

//         fetchEvents();
//     }, []);
// const mappedAppointments = useMemo(() => {

//   return events.map(appointment => ({
//     name: appointment.title,
//       age: appointment.age,
//       start: appointment.start,
//       end: appointment.end,
//       confirmed: appointment.confirmed,
//       reason: appointment.reason,
//       location: appointment.location,
//       color: appointment.color,
//   }))
// }, [events]);
  const [appointments, setAppointments] = useState(defaultAppointments);
  const [isOpen, setOpen] = useState(false);
  const [anchor, setAnchor] = useState(null);
  const [currentEvent, setCurrentEvent] = useState(null);
  const [info, setInfo] = useState('');
  const [time, setTime] = useState('');
  const [status, setStatus] = useState('');
  const [reason, setReason] = useState('');
  const [location, setLocation] = useState('');
  const [buttonText, setButtonText] = useState('');
  const [buttonType, setButtonType] = useState('');
  const [bgColor, setBgColor] = useState('');
  const [isToastOpen, setToastOpen] = useState(false);
  const [toastMessage, setToastMessage] = useState('');

  const timerRef = useRef(null);

  const myView = useMemo(() => ({ calendar: { type: 'week' } }), []);

  const handleEventHoverIn = useCallback((args) => {
    const event = args.event;
    const time = formatDate('hh:mm A', new Date(event.start)) + ' - ' + formatDate('hh:mm A', new Date(event.end));

    setCurrentEvent(event);

    // if (event.confirmed) {
    //   setStatus('Confirmed');
    //   setButtonText('Cancel appointment');
    //   setButtonType('warning');
    // } else {
    //   setStatus('Canceled');
    //   setButtonText('Confirm appointment');
    //   setButtonType('success');
    // }

    setBgColor(event.color);
    setInfo(event.title + ', Age: ' + event.age);
    setTime(time);
    setReason(event.reason);
    setLocation(event.location);

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

  const handleToastClose = useCallback(() => {
    setToastOpen(false);
  }, []);

  const setStatusButton = useCallback(() => {
    setOpen(false);
    const index = appointments.findIndex((item) => item.id === currentEvent.id);
    const newApp = [...appointments];
    newApp[index].confirmed = !appointments[index].confirmed;
    setAppointments(newApp);
    setToastMessage('Appointment ' + (currentEvent.confirmed ? 'confirmed' : 'canceled'));
    setToastOpen(true);
  }, [appointments, currentEvent]);

  // const viewFile = useCallback(() => {
  //   setOpen(false);
  //   setToastMessage('View file');
  //   setToastOpen(true);
  // }, []);

  // const deleteApp = useCallback(() => {
  //   setAppointments(appointments.filter((item) => item.id !== currentEvent.id));
  //   setOpen(false);
  //   setToastMessage('Appointment deleted');
  //   setToastOpen(true);
  // }, [appointments, currentEvent]);

  return (
    <>
      <Eventcalendar
        view={myView}
        data={appointments}
        clickToCreate={false}
        dragToCreate={false}
        dragToMove={true}
        dragToResize={false}
        showEventTooltip={false}
        height={260}
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
        // height={250}
        cssClass="md-tooltip"
      >
        <div className='pop' onMouseEnter={handleMouseEnter} onMouseLeave={handleMouseLeave}>
          <div className="md-tooltip-header" style={{ backgroundColor: '#87CEEB' }}>
            <span className="md-tooltip-name-age">{info}</span>
            <span className="md-tooltip-time">{time}</span>
          </div>
          <div className="md-tooltip-info">
            <div className="md-tooltip-title">
              Status: <span className="md-tooltip-status md-tooltip-text">{status}</span>
              <Button color={buttonType} variant="outline" className="md-tooltip-status-button" onClick={setStatusButton}>
                {buttonText}
              </Button>
            </div>
            <div className="md-tooltip-title">
              Reason for visit: <span className="md-tooltip-reason md-tooltip-text">{reason}</span>
            </div>
            <div className="md-tooltip-title">
              Location: <span className="md-tooltip-location md-tooltip-text">{location}</span>
            </div>
            {/* <Button color="secondary" className="md-tooltip-view-button" onClick={viewFile}>
              View patient file
            </Button>
            <Button color="danger" variant="outline" className="md-tooltip-delete-button" onClick={deleteApp}>
              Delete appointment
            </Button> */}
          </div>
        </div>
      </Popup>
      <Toast isOpen={isToastOpen} message={toastMessage} onClose={handleToastClose} />
    </>
  );
}

export default Calendar;