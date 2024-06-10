import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import './App.css';
import Search from './pages/search';
import Login from './pages/login/login';
import Settings from './pages/profile';
import BeDoctor from './pages/Doctor/form';
import Doctor from './pages/Doctor/doctor';
import AllBookedAppointments from './components/Doctor/allBookedAppointments';
import PatientProfile from './components/Doctor/patientProfile';
import ShowAllNotifications from './components/showAllnotifications';
import WritePriscription from './components/Doctor/writePrescription';
import CalendarSh from './components/Doctor/calendar';
import sLS from 'react-secure-storage';
import { useState, useEffect } from 'react';


function App() {
  const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);

  const [allAppointments, setAllAppointments] = useState([]);

    const fetchAllEvents = async () => {
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
            setAllAppointments(data);
        } catch (error) {
            console.error('Error fetching events:', error);
        }
    };
    useEffect(() => {
      fetchAllEvents();
  }, []);
  return (
    <Router>
      <div className="App">
      <Routes>
        <Route path='/' element={<Search />} />
        <Route path='/login' element={<Login />} />
        <Route path='/Settings' element={<Settings />} />
        <Route path='/be-doctor' element={<BeDoctor />} />
        <Route path='/doctor' element={<Doctor />} />
        <Route path='/cal' element={<CalendarSh  appointments={allAppointments} fetchEvents={fetchAllEvents} />} />

        <Route path='/AllBookedAppointments' element={<AllBookedAppointments />} />
        <Route path='/profile/:email' element={<PatientProfile />} />
        <Route path='/notifications' element={<ShowAllNotifications />} />
        <Route path='/prescription/:email' element={<WritePriscription />} />

      </Routes>
      </div>
    </Router>
  );
}

export default App;
