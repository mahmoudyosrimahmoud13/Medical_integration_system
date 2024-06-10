import React, { useState, useCallback, useRef } from 'react';
import sLS from 'react-secure-storage';
import Swal from 'sweetalert2';
import { Calendar } from 'react-date-range';
import 'react-date-range/dist/styles.css';
import 'react-date-range/dist/theme/default.css';

const CalendarSh = ({ appointments, fetchEvents }) => {
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    const [isOpen, setOpen] = useState(false);
    const [currentAppointments, setCurrentAppointments] = useState([]);
    const [tooltipPosition, setTooltipPosition] = useState({ top: 0, left: 0 });
    const timerRef = useRef(null);

    const handleDayHoverIn = useCallback((date, e) => {
        const filteredAppointments = appointments.filter(appointment =>
            new Date(appointment.date).toDateString() === date.toDateString()
        );

        setCurrentAppointments(filteredAppointments);

        if (timerRef.current) {
            clearTimeout(timerRef.current);
        }

        const rect = e.target.getBoundingClientRect();
        setTooltipPosition({ top: rect.top + window.scrollY, left: rect.left + window.scrollX });

        setOpen(true);
    }, [appointments]);

    const handleDayHoverOut = useCallback(() => {
        timerRef.current = setTimeout(() => {
            setOpen(false);
        }, 200);
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

    const cancelAppointment = async (appointment) => {
        try {
            const response = await fetch(`http://localhost:5225/Hospital/Doctor/CancelPatientDate?PatientEmail=${appointment.email}`, {
                method: "DELETE",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
            });
            if (!response.ok) {
                throw new Error('Failed to cancel appointment');
            }
            Swal.fire("Deleted!", "Your appointment has been deleted.", "success");
            fetchEvents();
        } catch (error) {
            console.error('Error canceling appointment:', error);
        }
    };

    const deleteBtn = (appointment) => {
        Swal.fire({
            title: "Are you sure you want to cancel this appointment?",
            icon: "warning",
            showCancelButton: true,
            confirmButtonText: "Yes, cancel it!",
            cancelButtonText: "No",
        }).then((result) => {
            if (result.isConfirmed) {
                cancelAppointment(appointment);
            }
        });
    };

    const renderTooltip = () => (
        <div
            className={`tooltip ${isOpen && currentAppointments.length > 0 ? 'visible' : ''}`}
            style={{ top: tooltipPosition.top, left: tooltipPosition.left }}
        >
            <div className='tooltip-content' onMouseEnter={handleMouseEnter} onMouseLeave={handleMouseLeave}>
                <h1>patients</h1>
                {currentAppointments.length > 0 ? (
                    currentAppointments.map((appointment) => (
                        <div key={appointment.id} className="tooltip-appointment">
                            <p>{appointment.patientName}</p>
                            <p>{appointment.from}</p>
                            <button onClick={() => deleteBtn(appointment)}>Cancel</button>
                        </div>
                    ))
                ) : (
                    <div>No appointments on this day.</div>
                )}
            </div>
        </div>
    );

    const dayHasAppointments = (date) => {
        return appointments.some(appointment =>
            new Date(appointment.date).toDateString() === date.toDateString()
        );
    };

    const renderDayContent = (day) => {
        const date = new Date(day);
        const hasAppointments = dayHasAppointments(date);

        return (
            <div
                className={`day ${hasAppointments ? 'has-appointments' : 'no-appointments'}`}
                onMouseEnter={(e) => handleDayHoverIn(date, e)}
                onMouseLeave={handleDayHoverOut}
            >
                {date.getDate()}
            </div>
        );
    };

    return (
        <div className='calendar-container'>
            <Calendar
                className='cal'
                date={new Date()}
                dayContentRenderer={renderDayContent}
            />
            {renderTooltip()}
        </div>
    );
};

export default CalendarSh;
