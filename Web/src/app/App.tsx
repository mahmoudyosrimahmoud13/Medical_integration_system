import { Navigate, Route, Routes } from 'react-router-dom';

import { useAuthStore } from '../core/auth/store';
import { AdminPage } from '../features/admin/AdminPage';
import { AppointmentsPage } from '../features/appointments/AppointmentsPage';
import { ForgotPasswordPage } from '../features/auth/ForgotPasswordPage';
import { LoginPage } from '../features/auth/LoginPage';
import { RegisterPage } from '../features/auth/RegisterPage';
import { ConversationPage } from '../features/chat/ConversationPage';
import { InboxPage } from '../features/chat/InboxPage';
import { DoctorApplyPage } from '../features/doctorPortal/DoctorApplyPage';
import { DoctorHomePage } from '../features/doctorPortal/DoctorHomePage';
import { DoctorPatientsPage } from '../features/doctorPortal/DoctorPatientsPage';
import { DoctorSchedulePage } from '../features/doctorPortal/DoctorSchedulePage';
import { DoctorDetailsPage } from '../features/doctors/DoctorDetailsPage';
import { FindDoctorsPage } from '../features/doctors/FindDoctorsPage';
import { HospitalHomePage } from '../features/hospital/HospitalHomePage';
import { HospitalsPage } from '../features/hospital/HospitalsPage';
import { PatientHomePage } from '../features/home/PatientHomePage';
import { LandingPage } from '../features/landing/LandingPage';
import { ProfilePage } from '../features/home/ProfilePage';
import { FindPharmacyPage } from '../features/pharmacy/FindPharmacyPage';
import { PharmacyHomePage } from '../features/pharmacy/PharmacyHomePage';
import { PharmacyStockPage } from '../features/pharmacy/PharmacyStockPage';
import { RecordsPage } from '../features/records/RecordsPage';
import { Shell } from './Shell';

function RequireAuth({ children }: { children: JSX.Element }) {
  const token = useAuthStore((s) => s.token);
  return token ? children : <Navigate to="/login" replace />;
}

function PublicOnly({ children }: { children: JSX.Element }) {
  const token = useAuthStore((s) => s.token);
  return token ? <Navigate to="/home" replace /> : children;
}

/** "/" is the landing page for visitors and the patient home for logged-in users. */
function Root() {
  const token = useAuthStore((s) => s.token);
  return token ? <Navigate to="/home" replace /> : <LandingPage />;
}

export function App() {
  return (
    <Routes>
      <Route path="/" element={<Root />} />
      <Route path="/login" element={<PublicOnly><LoginPage /></PublicOnly>} />
      <Route path="/register" element={<PublicOnly><RegisterPage /></PublicOnly>} />
      <Route path="/forgot-password" element={<PublicOnly><ForgotPasswordPage /></PublicOnly>} />
      <Route element={<RequireAuth><Shell /></RequireAuth>}>
        <Route path="home" element={<PatientHomePage />} />
        <Route path="doctors" element={<FindDoctorsPage />} />
        <Route path="doctors/:id" element={<DoctorDetailsPage />} />
        <Route path="appointments" element={<AppointmentsPage />} />
        <Route path="record" element={<RecordsPage />} />
        <Route path="pharmacies" element={<FindPharmacyPage />} />
        <Route path="hospitals" element={<HospitalsPage />} />
        <Route path="messages" element={<InboxPage />} />
        <Route path="messages/:id" element={<ConversationPage />} />
        <Route path="profile" element={<ProfilePage />} />
        <Route path="join/doctor" element={<DoctorApplyPage />} />
        <Route path="doctor" element={<DoctorHomePage />} />
        <Route path="doctor/patients" element={<DoctorPatientsPage />} />
        <Route path="doctor/schedule" element={<DoctorSchedulePage />} />
        <Route path="pharmacy" element={<PharmacyHomePage />} />
        <Route path="pharmacy/stock" element={<PharmacyStockPage />} />
        <Route path="hospital" element={<HospitalHomePage />} />
        <Route path="admin" element={<AdminPage />} />
        <Route path="*" element={<Navigate to="/home" replace />} />
      </Route>
    </Routes>
  );
}
