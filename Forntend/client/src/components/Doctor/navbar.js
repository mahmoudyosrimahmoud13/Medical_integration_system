import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import logo from '../../photos/logo1.png';
import dashIcon from '../../photos/dashboards.png';
import calenderIcon from '../../photos/calendar.png';
import patientIcon from '../../photos/user.png';
import chatIcon from '../../photos/messenger.png';
import joinIcon from '../../photos/join.png';
import settingsIcon from '../../photos/setting.png';

const Navbar = () => {
    const location = useLocation();
    const [activeLink, setActiveLink] = useState(location.pathname);

    useEffect(() => {
        setActiveLink(location.pathname);
    }, [location]);

    const handleLinkClick = (path) => {
        setActiveLink(path);
    };

    return (
        <div className="navbar">
            <div className='logo'>
                <img src={logo} alt="not found" />
            </div>
            <div className='links'>
                <Link
                    className={`link ${activeLink === '/doctor' ? 'active' : ''}`}
                    to={'/doctor'}
                    onClick={() => handleLinkClick('/doctor')}
                >
                    <img src={dashIcon} alt='not found' />dashboard
                </Link>
                <Link
                    className={`link ${activeLink === '/allbookedappointments' ? 'active' : ''}`}
                    to={'/allbookedappointments'}
                    onClick={() => handleLinkClick('/allBookedAppointments')}
                >
                    <img src={calenderIcon} alt='not found' />appointments
                </Link>
                <Link
                    className={`link ${activeLink === '/patients' ? 'active' : ''}`}
                    to={'/patients'}
                    onClick={() => handleLinkClick('/patients')}
                >
                    <img src={patientIcon} alt='not found' />patients
                </Link>
                <Link
                    className={`link ${activeLink === '/chat' ? 'active' : ''}`}
                    to={'/chat'}
                    onClick={() => handleLinkClick('/chat')}
                >
                    <img src={chatIcon} alt='not found' />chat
                </Link>
                <Link
                    className={`link ${activeLink === '/be-doctor' ? 'active' : ''}`}
                    to={'/be-doctor'}
                    onClick={() => handleLinkClick('/be-doctor')}
                >
                    <img src={joinIcon} alt='not found' />our medical team
                </Link>
                <Link
                    className={`link ${activeLink === '/settings' ? 'active' : ''}`}
                    to={'/settings'}
                    onClick={() => handleLinkClick('/settings')}
                >
                    <img src={settingsIcon} alt='not found' />settings
                </Link>
            </div>
        </div>
    );
};

export default Navbar;
