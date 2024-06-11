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
import AcceptDoctors from './pages/adminAccept';
import Patients from './components/Doctor/patients';


function App() {

  return (
    <Router>
      <div className="App">
      <Routes>
        <Route path='/search' element={<Search />} />
        <Route path='/' element={<Login />} />
        <Route path='/Settings' element={<Settings />} />
        <Route path='/be-doctor' element={<BeDoctor />} />
        <Route path='/doctor' element={<Doctor />} />
        <Route path='/allbookedappointments' element={<AllBookedAppointments />} />
        <Route path='/patients' element={<Patients />} />
        <Route path='/profile/:email' element={<PatientProfile />} />
        <Route path='/notifications' element={<ShowAllNotifications />} />
        <Route path='/prescription/:email' element={<WritePriscription />} />
        <Route path='/applicants' element={<AcceptDoctors />} />
      </Routes>
      </div>
    </Router>
  );
}

export default App;
