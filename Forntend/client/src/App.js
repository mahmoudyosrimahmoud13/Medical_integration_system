import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import './App.css';
import Home from './pages/home';
import Login from './pages/login/login';
import Settings from './pages/profile';
import BeDoctor from './pages/Doctor/form';
import Doctor from './pages/Doctor/doctor';


function App() {
  return (
    <Router>
      <div className="App">
      <Routes>
        <Route path='/' element={<Home />} />
        <Route path='/login' element={<Login />} />
        <Route path='/Settings' element={<Settings />} />
        <Route path='/be-doctor' element={<BeDoctor />} />
        <Route path='/doctor' element={<Doctor />} />

      </Routes>
      </div>
    </Router>
  );
}

export default App;
