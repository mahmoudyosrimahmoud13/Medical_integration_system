import { Link } from 'react-router-dom';
import logo from '../../photos/logo1.png';
import dashIcon from '../../photos/dashboards.png';
import calenderIcon from '../../photos/calendar.png';
import patientIcon from '../../photos/user.png';
import chatIcon from '../../photos/messenger.png';
import reportsIcon from '../../photos/bar-chart.png';
import settingsIcon from '../../photos/setting.png';


const Navbar = () => {
    return(
        <>
            <div className="navbar">
                <div className='logo'>
                    <img src={logo} alt="not found" />
                </div>
                <div className='links'>
                    <Link className='link' to={'/doctor'}><img src={dashIcon} alt='not found' />dashboard</Link>
                    <Link className='link' to={''}><img src={calenderIcon} alt='not found' />appointments</Link>
                    <Link className='link' to={''}><img src={patientIcon} alt='not found' />patients</Link>
                    <Link className='link' to={''}><img src={chatIcon} alt='not found' />chat</Link>
                    <Link className='link' to={''}><img src={reportsIcon} alt='not found' />reports</Link>
                    <Link className='link' to={'/settings'}><img src={settingsIcon} alt='not found' />settings</Link>
                </div>
            </div>
        </>
    )
}

export default Navbar;