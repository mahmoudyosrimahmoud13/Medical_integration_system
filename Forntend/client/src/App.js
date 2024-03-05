import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import './App.css';
import Home from './pages/home';
import Login from './pages/login/login';
import Profile from './pages/profile';
import BeDoctor from './pages/Doctor/form';

function App() {
  return (
    <Router>
      <div className="App">
      <Routes>
        <Route path='/' element={<Home />} />
        <Route path='/login' element={<Login />} />
        <Route path='/profile' element={<Profile />} />
        <Route path='/bedoctor' element={<BeDoctor />} />
      </Routes>
      </div>
    </Router>
  );
}

export default App;
